defmodule Moba.Admin do
  @moduledoc """
  Top-level domain for the admin panel, mostly generated by Torch
  """

  alias Moba.Admin
  alias Admin.{Skills, Items, Avatars, Seasons, Users, Server, Skins, Duels, Matches}

  # SKILLS

  def paginate_skills(params \\ %{}), do: Skills.paginate(params)

  def list_skills, do: Skills.list()

  def get_skill!(id), do: Skills.get!(id)

  def create_skill(attrs \\ %{}), do: Skills.create(attrs)

  def update_skill(skill, attrs), do: Skills.update(skill, attrs)

  def delete_skill(skill), do: Skills.delete(skill)

  def change_skill(skill), do: Skills.change(skill)

  def skills_with_same_code(code), do: Skills.list_with_same_code(code)

  # ITEMS

  def paginate_items(params \\ %{}), do: Items.paginate(params)

  def list_items, do: Items.list()

  def get_item!(id), do: Items.get!(id)

  def create_item(attrs \\ %{}), do: Items.create(attrs)

  def update_item(item, attrs), do: Items.update(item, attrs)

  def delete_item(item), do: Items.delete(item)

  def change_item(item), do: Items.change(item)

  # AVATARS

  def paginate_avatars(params \\ %{}), do: Avatars.paginate(params)

  def list_avatars, do: Avatars.list()

  def get_avatar!(id), do: Avatars.get!(id)

  def create_avatar(attrs \\ %{}), do: Avatars.create(attrs)

  def update_avatar(avatar, attrs), do: Avatars.update(avatar, attrs)

  def delete_avatar(avatar), do: Avatars.delete(avatar)

  def change_avatar(avatar), do: Avatars.change(avatar)

  # USERS

  def paginate_users(params \\ %{}), do: Users.paginate(params)

  def list_users, do: Users.list()

  def get_user!(id), do: Users.get!(id)

  def create_user(attrs \\ %{}), do: Users.create(attrs)

  def update_user(user, attrs), do: Users.update(user, attrs)

  def delete_user(user), do: Users.delete(user)

  def change_user(user), do: Users.change(user)

  def get_user_stats, do: Users.get_stats()

  # SEASONS

  def paginate_seasons(params \\ %{}), do: Seasons.paginate(params)

  def list_seasons, do: Seasons.list()

  def list_recent_seasons, do: Seasons.list_recent()

  def get_season!(id), do: Seasons.get!(id)

  def update_season(season, attrs), do: Seasons.update(season, attrs)

  def change_season(season), do: Seasons.change(season)

  defdelegate current_active_players, to: Seasons

  defdelegate current_guests, to: Seasons

  defdelegate players_count, to: Seasons

  defdelegate heroes_count, to: Seasons

  defdelegate matches_count, to: Seasons

  defdelegate masters_count, to: Seasons

  defdelegate grandmasters_count, to: Seasons

  defdelegate undefeated_count, to: Seasons

  defdelegate active_players_count, to: Seasons

  defdelegate trained_heroes_count, to: Seasons

  # SKINS

  def paginate_skins(params \\ %{}), do: Skins.paginate(params)

  def list_skins, do: Skins.list()

  def get_skin!(id), do: Skins.get!(id)

  def create_skin(attrs \\ %{}), do: Skins.create(attrs)

  def update_skin(skin, attrs), do: Skins.update(skin, attrs)

  def delete_skin(skin), do: Skins.delete(skin)

  def change_skin(skin), do: Skins.change(skin)

  # DUELS

  def list_recent_duels, do: Duels.list_recent()

  # MATCHES

  defdelegate match_stats, to: Matches

  # SERVER

  def get_server_data, do: Server.get_data()
end
