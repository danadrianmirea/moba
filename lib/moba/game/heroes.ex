defmodule Moba.Game.Heroes do
  @moduledoc """
  Manages Hero records and queries.
  See Moba.Game.Schema.Hero for more info.
  """
  alias Moba.{Repo, Game}
  alias Game.Schema.Hero
  alias Game.Query.{HeroQuery, SkillQuery}

  # -------------------------------- PUBLIC API

  def get!(nil), do: nil

  def get!(id) do
    Hero
    |> Repo.get(id)
    |> base_preload()
  end

  def list_latest(user_id) do
    HeroQuery.latest(user_id)
    |> Repo.all()
    |> base_preload()
  end

  def list_pvp_eligible(user_id, duel_inserted_at) do
    HeroQuery.eligible_for_pvp(user_id, duel_inserted_at)
    |> Repo.all()
    |> base_preload()
  end

  def create!(attrs, user, avatar) do
    %Hero{}
    |> Hero.create_changeset(attrs, user, avatar)
    |> Repo.insert!()
  end

  @doc """
  Creates a bot Hero, automatically leveling it and its skills.
  Level 0 bots exist to serve as weak targets for newly created player Heroes,
  and thus have their stats greatly reduced
  """
  def create_bot!(avatar, level, difficulty, league_tier, user \\ nil) do
    name = if user, do: user.username, else: avatar.name

    bot =
      create!(
        %{
          bot_difficulty: difficulty,
          name: name,
          gold: 100_000,
          league_tier: league_tier,
          total_gold_farm: bot_total_gold_farm(league_tier, difficulty),
        },
        user,
        avatar
      )

    if level > 0 do
      xp = Moba.xp_until_hero_level(level)

      bot
      |> add_experience!(xp)
      |> Game.generate_bot_build!()
      |> level_up_skills()
    else
      bot
      |> Game.generate_bot_build!()
      |> update!(%{
        total_hp: bot.total_hp - avatar.hp_per_level * 3,
        total_mp: bot.total_mp - avatar.mp_per_level * 3,
        atk: bot.atk - avatar.atk_per_level * 3,
        level: 0
      })
    end
  end

  def update!(nil, _), do: nil

  def update!(hero, attrs, items \\ nil) do
    hero = if items, do: Repo.preload(hero, :items), else: hero

    hero
    |> Hero.replace_items(items)
    |> Hero.changeset(attrs)
    |> Repo.update!()
  end

  @doc """
  Only attackers are rewarded with XP in PVE (Jungle) battles.
  If they happen to reach the max league (Master), they are
  automatically pushed to level 25 (max level).
  """
  def update_attacker!(hero, updates) do
    {xp, updates} = Map.pop(updates, :total_xp)

    hero
    |> update!(updates)
    |> add_experience!(xp)
  end

  @doc """
  Used for easy testing in development, unavailable in production
  """
  def level_cheat(hero) do
    xp = Moba.xp_to_next_hero_level(hero.level + 1)

    updated =
      hero
      |> add_experience!(xp)
      |> update!(%{gold: 100_000})

    if updated.level == 25 do
      update!(updated, %{league_tier: 5}) |> Game.generate_boss!()
    else
      updated
    end
  end

  def pve_win_rate(hero) do
    sum = hero.wins + hero.ties + hero.losses

    if sum > 0 do
      round(hero.wins * 100 / sum)
    else
      0
    end
  end

  def pvp_win_rate(hero) do
    sum = hero.pvp_wins + hero.pvp_losses

    if sum > 0 do
      round(hero.pvp_wins * 100 / sum)
    else
      0
    end
  end

  @doc """
  Grabs heroes with pve_rankings close to the target hero
  """
  def pve_search(%{pve_ranking: ranking}) when not is_nil(ranking) do
    {min, max} =
      if ranking <= 6 do
        {1, 10}
      else
        {ranking - 5, ranking + 5}
      end

    HeroQuery.non_bots()
    |> HeroQuery.by_pve_ranking(min, max)
    |> Repo.all()
    |> avatar_preload()
  end

  def pve_search(%{total_gold_farm: total_gold_farm, bot_difficulty: bot}) when not is_nil(bot) do
    HeroQuery.non_bots()
    |> HeroQuery.by_total_gold_farm(total_gold_farm - 2000, total_gold_farm + 2000)
    |> HeroQuery.limit_by(10)
    |> Repo.all()
    |> avatar_preload()
  end

  def pve_search(%{total_gold_farm: total_gold_farm, id: id} = hero) do
    by_farm =
      HeroQuery.non_bots()
      |> HeroQuery.by_total_gold_farm(total_gold_farm - 5000, total_gold_farm + 5000)
      |> Repo.all()
      |> avatar_preload()

    with_hero = Enum.sort_by(by_farm ++ [hero], &(&1.total_gold_farm + &1.total_xp_farm), :desc)

    hero_index = Enum.find_index(with_hero, &(&1.id == id))

    with_hero
    |> Enum.with_index()
    |> Enum.filter(fn {_, index} ->
      index >= hero_index - 4 && index <= hero_index + 5
    end)
    |> Enum.map(fn {elem, _} -> elem end)
  end

  @doc """
  Retrieves top PVE ranked Heroes
  """
  def pve_ranking(limit) do
    HeroQuery.pve_ranked()
    |> HeroQuery.limit_by(limit)
    |> Repo.all()
    |> base_preload()
  end

  @doc """
  Grabs all Heroes ordered by their total_gold_farm and updates their pve_ranking
  """
  def update_pve_ranking! do
    Repo.update_all(Hero, set: [pve_ranking: nil])

    HeroQuery.non_bots()
    |> HeroQuery.finished_pve()
    |> HeroQuery.in_current_ranking_date()
    |> Repo.all()
    |> Enum.with_index(1)
    |> Enum.map(fn {hero, index} ->
      update!(hero, %{pve_ranking: index})
    end)
  end

  def prepare_league_challenge!(hero), do: update!(hero, %{league_step: 1})

  def collection_for(user_id) do
    HeroQuery.finished_pve()
    |> HeroQuery.with_user(user_id)
    |> HeroQuery.unarchived()
    |> Repo.all()
    |> Repo.preload(:avatar)
    |> Enum.group_by(& &1.avatar.code)
    |> Enum.map(fn {code, heroes} ->
      {
        code,
        Enum.sort_by(heroes, &{&1.pve_ranking, &1.league_tier, &1.total_gold_farm + &1.total_xp_farm}, :desc)
        |> List.first()
      }
    end)
    |> Enum.sort_by(fn {_code, hero} -> {hero.league_tier, hero.total_gold_farm + hero.total_xp_farm} end, :desc)
    |> Enum.map(fn {code, hero} -> %{code: code, hero_id: hero.id, tier: hero.league_tier, avatar: hero.avatar} end)
  end

  def set_skin!(hero, %{id: nil}), do: update!(hero, %{skin_id: nil}) |> Map.put(:skin, nil)
  def set_skin!(hero, skin), do: update!(hero, %{skin_id: skin.id}) |> Map.put(:skin, skin)

  def buyback_price(%{level: level}), do: level * Moba.buyback_multiplier()

  def buyback!(%{pve_state: "dead"} = hero) do
    price = buyback_price(hero)

    if hero.gold >= price do
      update!(hero, %{
        pve_state: "alive",
        buybacks: hero.buybacks + 1,
        gold: hero.gold - price,
        total_gold_farm: hero.total_gold_farm - price
      })
    else
      hero
    end
  end

  def buyback!(hero), do: hero

  def start_farming!(hero, state, turns) do
    update!(hero, %{pve_state: state, pve_farming_turns: turns, pve_farming_started_at: Timex.now()})
  end

  def finish_farming!(
        %{
          pve_farming_turns: farming_turns,
          pve_current_turns: current_turns,
          pve_farming_rewards: rewards,
          pve_farming_started_at: started,
          pve_state: state
        } = hero
      ) do
    remaining_turns = zero_limit(current_turns - farming_turns)

    {hero, amount} = apply_farming_rewards(hero, farming_turns, state)

    new_reward = [%{state: state, started_at: started, turns: farming_turns, amount: amount}]

    hero
    |> Hero.replace_farming_rewards(rewards ++ new_reward)
    |> update!(%{
      pve_state: "alive",
      pve_farming_turns: 0,
      pve_farming_started_at: nil,
      pve_current_turns: remaining_turns
    })
  end

  # --------------------------------

  defp add_experience!(hero, nil), do: hero

  defp add_experience!(hero, experience) do
    hero = Repo.preload(hero, :user)
    if hero.user, do: Moba.add_user_experience(hero.user, experience)

    hero
    |> Hero.changeset(%{experience: hero.experience + experience, total_xp_farm: hero.total_xp_farm + experience})
    |> check_if_leveled()
    |> Repo.update!()
  end

  defp apply_farming_rewards(hero, turns, "meditating") do
    rewards = turns * Enum.random(Moba.farm_per_turn(hero.pve_tier))
    hero = add_experience!(hero, rewards)

    {hero, rewards}
  end

  defp apply_farming_rewards(hero, turns, "mining") do
    rewards = turns * Enum.random(Moba.farm_per_turn(hero.pve_tier))
    hero = update!(hero, %{gold: hero.gold + rewards, total_gold_farm: hero.total_gold_farm + rewards})

    {hero, rewards}
  end

  defp check_if_leveled(%{data: data, changes: changes} = changeset) do
    level = changes[:level] || data.level
    xp = changes[:experience] || 0
    diff = Moba.xp_to_next_hero_level(level + 1) - xp

    if diff <= 0 do
      changeset
      |> Hero.level_up(level, diff * -1)
      |> check_if_leveled()
    else
      changeset
    end
  end

  # randomly levels up skills for a bot
  defp level_up_skills(hero) do
    hero = Repo.preload(hero, active_build: [:skills])
    ultimate = Enum.find(hero.active_build.skills, fn skill -> skill.ultimate end)
    hero = Enum.reduce(1..3, hero, fn _, acc -> Game.level_up_skill!(acc, ultimate.code) end)

    Enum.reduce(1..100, hero, fn _, acc ->
      skill = Enum.shuffle(acc.active_build.skills) |> List.first()
      Game.level_up_skill!(acc, skill.code)
    end)
  end

  defp bot_total_gold_farm(league_tier, difficulty) do
    base = bot_total_gold_farm_base(league_tier, difficulty)
    extra_farm = zero_limit(league_tier - 3)

    range =
      case difficulty do
        # 0..800
        "weak" -> 0..2
        # 800..1600
        "moderate" -> 2..4
        # 1600..3200
        "strong" -> (4 + extra_farm)..(6 + extra_farm)
        # 19_200..24_000
        "pvp_master" -> 0..12
        # 26_400..30_000
        "pvp_grandmaster" -> 6..15
      end

    base + 400 * Enum.random(range)
  end

  defp bot_total_gold_farm_base(tier, difficulty) when difficulty in ["pvp_master", "pvp_grandmaster"],
    do: (tier - 1) * 4800

  defp bot_total_gold_farm_base(tier, _), do: tier * 4800

  defp base_preload(struct_or_structs, extras \\ []) do
    Repo.preload(
      struct_or_structs,
      [:user, :avatar, :items, :skin, active_build: [skills: SkillQuery.ordered()]] ++ extras
    )
  end

  defp avatar_preload(struct_or_structs) do
    Repo.preload(struct_or_structs, :avatar)
  end

  defp zero_limit(total) when total < 0, do: 0
  defp zero_limit(total), do: total
end
