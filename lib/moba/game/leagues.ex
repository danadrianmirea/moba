defmodule Moba.Game.Leagues do
  @moduledoc """
  Manages gameplay logic related to the League Challenge.
  More information on Moba.Engine.Core.League
  """

  alias Moba.{Repo, Game}
  alias Game.Query.HeroQuery

  # -------------------------------- PUBLIC API

  def max_step_for(tier) do
    case tier do
      0 -> 2
      1 -> 3
      2 -> 4
      _ -> 5
    end
  end

  @doc """
  When in a League Challenge, the attacker faces consecutive defenders in order to rank up.
  These defenders get stronger with higher levels and difficulty as the challenge progresses
  """
  def defender_for(%{league_step: step} = attacker) do
    case step do
      0 -> easiest_defender(attacker)
      1 -> easiest_defender(attacker)
      2 -> easy_defender(attacker)
      3 -> moderate_defender(attacker)
      4 -> moderate_defender(attacker)
      5 -> hard_defender(attacker)
    end
  end

  def tier_for(level) do
    Enum.find((0..5), fn tier -> base_level(tier) + 3 > level end) || 0
  end

  # --------------------------------

  # this is a small facilitator: the #league_defender query returns 3 heroes and this makes sure the
  # one with lowest HP is chosen to avoid unlucky and frustrating battles against super tanks
  defp get_first(query) do
    query |> Repo.all() |> Enum.sort_by(fn hero -> hero.total_hp end, :asc) |> List.first()
  end

  defp easiest_defender(%{id: id, league_tier: league_tier}) do
    HeroQuery.league_defender(id, base_level(league_tier), "weak", Game.current_match().id)
    |> get_first()
  end

  defp easy_defender(%{id: id, league_tier: league_tier}) do
    HeroQuery.league_defender(id, base_level(league_tier) + 1, "weak", Game.current_match().id)
    |> get_first()
  end

  defp moderate_defender(%{id: id, league_tier: league_tier}) do
    HeroQuery.league_defender(id, base_level(league_tier) + 2, "moderate", Game.current_match().id)
    |> get_first()
  end

  defp hard_defender(%{id: id, league_tier: league_tier}) do
    HeroQuery.league_defender(id, base_level(league_tier) + 3, "strong", Game.current_match().id)
    |> get_first()
  end

  defp base_level(tier) do
    case tier do
      0 -> 6
      1 -> 10
      2 -> 14
      3 -> 18
      4 -> 22
      5 -> 25
    end
  end
end
