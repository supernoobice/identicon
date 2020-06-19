defmodule Identicon do
  @moduledoc """
  Identicon creates an icon based on the hex value of your input.
  """

  @doc """
  The main method.
  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_grid
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
  Saves the image of binary data.
  """
  def save_image(bin_image, filename) do
    File.write('#{filename}.png', bin_image)
  end

  @doc """
  Draws the image using erlang egd.
  """
  def draw_image(%Identicon.Image{pixel_map: pixel_map, color: color}) do
    image = :egd.create(250, 250)
    color = :egd.color(color)

    Enum.each pixel_map, fn(coor) ->
      {top, bottom} = coor
      :egd.filledRectangle(image, top, bottom, color)
    end

    :egd.render(image)
  end

  @doc """
  Build the pixel map. Returns the top and bottom coordinates for image building.
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_val, index}) ->
      # top
      x = rem(index, 5) * 50
      y = div(index, 5) * 50
      top = {x, y}

      # bottom
      bottom = {x + 50, y + 50}

      {top, bottom}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
  Filters only the even values.
  """
  def filter_grid(%Identicon.Image{grid: grid} = image) do
    even = grid
    |> Enum.filter(&filter_even/1)

    %Identicon.Image{image | grid: even}
  end

  @doc """
  Helper for filter_grid
  """
  def filter_even(item) do
    {value, _tail} = item
    rem(value, 2) == 0 # even
  end

  @doc """
  Builds the grid, a list of values taken from the hex value of input.
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do # Pattern matches the image struct and get the hex key
    grid = hex
    |> Enum.chunk_every(3, 3, :discard) # Make the hex list into chucks of 3
    |> Enum.map(&mirror_row/1) # Enumerate each row and call mirror_row
    |> List.flatten
    |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row([first, second | _tail ] = row) do
    row ++ [second, first]
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{ image | color: {r, g, b}}
  end

  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end
end
