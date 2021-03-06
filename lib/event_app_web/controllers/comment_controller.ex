defmodule EventAppWeb.CommentController do
  use EventAppWeb, :controller

  alias EventApp.Comments
  alias EventApp.Invites
  alias EventApp.Events

  alias EventAppWeb.Helpers
  alias EventAppWeb.Plugs
  plug Plugs.RequireUser
  plug :fetch_event_for_delete when action in [:delete]
  plug Plugs.FetchEvent when not action in [:delete]
  plug :require_invitee_or_owner
  plug :require_comment_or_event_owner when action in [:delete]

  def fetch_event_for_delete(conn, _params) do
    id = conn.params["id"]
    comment = Comments.get_comment!(id)
    assign(conn, :event, comment.event)
  end

  def require_invitee_or_owner(conn, _args) do
    if Helpers.is_user_invited_or_owns?(conn) do
      conn
    else
      conn
      |> put_flash(:error, "You do not have an invite to this event.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def require_comment_or_event_owner(conn, _args) do
    id = conn.params["id"]
    comment = Comments.get_comment!(id)
    owns_comment? = Helpers.current_user_is?(conn, comment)
    event = comment.event
    owns_event? = Helpers.current_user_is?(conn, event.user_id)
    if owns_comment? || owns_event? do
      conn
    else
      conn
      |> put_flash(:error, "You must own this comment or event to do that.")
      |> redirect(to: Routes.event_path(conn, :show, event))
      |> halt()
    end
  end

  def create(conn, %{"comment" => comment_params}) do
    user = conn.assigns[:current_user]
    event = conn.assigns[:event]
    comment_params = comment_params
    |> Map.put("user_id", user.id)
    |> Map.put("event_id", event.id)

    case Comments.create_comment(comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment created successfully.")
        |> redirect(to: Routes.event_path(conn, :show, event))

      {:error, %Ecto.Changeset{} = changeset} ->
        invites = Invites.list_invites(event.id)
        comments = Comments.list_comments(event.id)
        conn
        |> put_view(EventAppWeb.EventView)
        |> render(:show, event: event, invites: invites, comments: comments, comment_changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    comment = Comments.get_comment!(id)
    {:ok, _} = Comments.delete_comment(comment)

    conn
    |> put_flash(:info, "Comment deleted successfully.")
    |> redirect(to: Routes.event_path(conn, :show, comment.event))
  end
end
