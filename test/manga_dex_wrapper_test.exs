defmodule MangaDexWrapperTest do
  use ExUnit.Case
  doctest MangaDexWrapper

  test "retrieves manga list" do
    {:ok, %{"results" => results, "offset" => offset, "total" => total}} = MangaDexWrapper.get_manga_list("Kobayashi's Dragon Maid")
    assert is_list(results)
    if offset < total, do:  IO.inspect(hd(results))
  end

  test "retrieves chapter list" do
    {:ok, %{"results" => results, "offset" => offset, "total" => total}} = MangaDexWrapper.get_manga_chapters("67b35ba4-9c53-4957-91e7-4f7884e4b412")
    assert is_list(results)
    if offset < total, do:  IO.inspect(hd(results)) 
  end

  test "retrieves chapter" do
    {:ok, data} = MangaDexWrapper.get_details_for_reading("e11fec05-ea17-4654-8797-abb86ab6d06d")
    assert true
  end 
end
