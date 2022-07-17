defmodule Moba.Game.Schema.QuestProgression do
  @moduledoc """
  Represents the connection between players and quests, where progress is recorded
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Moba.{Accounts, Game}

  schema "quest_progressions" do
    field :current_value, :integer, default: 0
    field :completed_at, :utc_datetime
    field :history_codes, {:array, :string}, default: []

    belongs_to :user, Accounts.Schema.User
    belongs_to :quest, Game.Schema.Quest
    belongs_to :player, Game.Schema.Player

    timestamps()
  end

  def changeset(progression, attrs) do
    progression
    |> cast(attrs, [
      :current_value,
      :completed_at,
      :history_codes
    ])
  end
end
