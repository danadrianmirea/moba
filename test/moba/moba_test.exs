defmodule Moba.MobaTest do
  use Moba.DataCase

  describe "pvp_points" do
    test "attacker win" do
      assert Moba.attacker_win_pvp_points(200, 6) == 19
      assert Moba.attacker_win_pvp_points(100, 6) == 14
      assert Moba.attacker_win_pvp_points(80, 6) == 13
      assert Moba.attacker_win_pvp_points(40, 6) == 11
      assert Moba.attacker_win_pvp_points(0, 6) == 9
      assert Moba.attacker_win_pvp_points(-40, 6) == 7
      assert Moba.attacker_win_pvp_points(-80, 6) == 2
      assert Moba.attacker_win_pvp_points(-100, 6) == 2
    end

    test "attacker loss" do
      assert Moba.attacker_loss_pvp_points(100, 6) == -2
      assert Moba.attacker_loss_pvp_points(80, 6) == -2
      assert Moba.attacker_loss_pvp_points(40, 6) == -7
      assert Moba.attacker_loss_pvp_points(0, 6) == -9
      assert Moba.attacker_loss_pvp_points(-40, 6) == -11
      assert Moba.attacker_loss_pvp_points(-80, 6) == -13
      assert Moba.attacker_loss_pvp_points(-100, 6) == -14
      assert Moba.attacker_loss_pvp_points(-200, 6) == -19
    end

    test "defender win" do
      assert Moba.defender_win_pvp_points(100, 6) == 0
      assert Moba.defender_win_pvp_points(80, 6) == 0
      assert Moba.defender_win_pvp_points(40, 6) == 0
      assert Moba.defender_win_pvp_points(0, 6) == 2
      assert Moba.defender_win_pvp_points(-40, 6) == 4
      assert Moba.defender_win_pvp_points(-80, 6) == 6
      assert Moba.defender_win_pvp_points(-100, 6) == 7
      assert Moba.defender_win_pvp_points(-200, 6) == 12
    end

    test "defender loss" do
      assert Moba.defender_loss_pvp_points(200, 6) == -12
      assert Moba.defender_loss_pvp_points(100, 6) == -7
      assert Moba.defender_loss_pvp_points(80, 6) == -6
      assert Moba.defender_loss_pvp_points(40, 6) == -4
      assert Moba.defender_loss_pvp_points(0, 6) == -2
      assert Moba.defender_loss_pvp_points(-40, 6) == 0
      assert Moba.defender_loss_pvp_points(-80, 6) == 0
      assert Moba.defender_loss_pvp_points(-100, 6) == 0
    end
  end

  describe "cross-domain functions" do
    test "#create_current_pve_hero!" do
      user = create_user()
      avatar = base_avatar()
      skills = base_skills()

      hero = Moba.create_current_pve_hero!(%{name: "Foo"}, user, avatar, skills)
      hero = Game.get_hero!(hero.id)
      user = Accounts.get_user!(user.id)

      assert hero
      assert user.current_pve_hero_id == hero.id
    end
  end
end
