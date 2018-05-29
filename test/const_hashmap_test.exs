defmodule ConstHashmapTest do
    use ExUnit.Case
    doctest ConstHashmap

    test "format base" do
        assert (%ConstHashmap{} |> ConstHashmap.format) == "%ConstHashmap{\n}"
    end

    test "insert base" do
        hm = %ConstHashmap{} 
            |> ConstHashmap.insert("hello", "world") 
            |> ConstHashmap.format
        
        assert hm == "%ConstHashmap{\n    \"hello\": \"world\"\n}"
    end

    test "multiple insert" do
        hm = %ConstHashmap{} 
            |> ConstHashmap.insert("hello", "world")
            |> ConstHashmap.insert("goodbye", "planet")
            |> ConstHashmap.format
        
        assert hm == "%ConstHashmap{\n    \"hello\": \"world\"\n    \"goodbye\": \"planet\"\n}"
    end

    test "insert replace key" do
        hm = %ConstHashmap{} 
            |> ConstHashmap.insert("hello", "world")
            |> ConstHashmap.insert("hello", "planet")
            |> ConstHashmap.format
        
        assert hm == "%ConstHashmap{\n    \"hello\": \"planet\"\n}"
    end
end
