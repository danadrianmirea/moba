defmodule Moba.Admin.Duels do
  @moduledoc """
  Admin functions for managing Matches, mostly generated by Torch package.
  """

  alias Moba.{Repo, Game}
  alias Game.Schema.Duel

  import Ecto.Query

  def list_recent do
    Repo.all(
      from duel in Duel,
        limit: 20,
        join: player in assoc(duel, :player),
        where: is_nil(player.bot_options),
        where: duel.auto == false,
        order_by: [desc: duel.id]
    )
    |> Repo.preload(player: :user, opponent_player: :user, winner_player: :user)
  end

  def get!(id), do: Repo.get!(Duel, id)
end
