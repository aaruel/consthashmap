defmodule ConstHashmap.Element do
    @type t :: %__MODULE__{
        key: any(),
        value: any(),
        reference_index: non_neg_integer() | nil
    }

    defstruct   key: nil,
                value: nil,
                reference_index: nil

    def format(%__MODULE__{key: key, value: value}) do
        "    " <> inspect(key) <> ": " <> inspect(value) <> "\n"
    end
    
    def insert(key, value) do
        %__MODULE__{key: key, value: value}
    end
end

defmodule ConstHashmap.Tools do
    defp generate_nsize_list(size, element, list \\ []) when is_integer(size) do
        if size > 0 do
            generate_nsize_list(size - 1, element, list ++ [element])
        else
            list
        end
    end

    def modify_index([front | back], index, func) when is_function(func) do
        if index > 0 do
            [front] ++ modify_index(back, index - 1, func)
        else
            [func.(front)] ++ back
        end
    end

    def modify_cond([front | back], condition, func) when is_function(func) and is_function(condition) do
        if condition.(front) do
            [func.(front)] ++ back
        else
            [front] ++ modify_cond(back, condition, func)
        end
    end

    def pow2_signed(power) do
        :math.pow(2, power) |> trunc
    end

    def two_power_openings(power) when is_integer(power) do
        0..(pow2_signed(power) - 1) |> Enum.to_list
    end

    def two_power_data(power) when is_integer(power) do
        list = generate_nsize_list(pow2_signed(power), %ConstHashmap.Element{})
        list |> List.to_tuple
    end
end

defmodule ConstHashmap.Pool do
    import Bitwise

    @power_size 3
    @standard_openings ConstHashmap.Tools.two_power_openings(@power_size)

    @type t :: %__MODULE__{
        openings: [non_neg_integer()],
        data: {ConstHashmap.Element.t}
    }

    defstruct   openings: @standard_openings,
                data: ConstHashmap.Tools.two_power_data(@power_size)

    def hash(key, mask_size) do
        <<hk :: size(mask_size), _data :: bitstring>> = :crypto.hash(:sha256, inspect(key))
        hk
    end

    def format(%__MODULE__{data: data, openings: openings}) do
        occupied = @standard_openings -- openings
        Enum.map(occupied, fn index -> 
            elem(data, index) |> ConstHashmap.Element.format
        end) |> List.to_string
    end

    def insert(%__MODULE__{data: data, openings: openings}, key, value) do
        hash_index = hash(key, 3)
        u_openings = Enum.filter(openings, fn n -> n != hash_index end)
        u_data = put_elem(data, hash_index, ConstHashmap.Element.insert(key, value))
        
        %__MODULE__{data: u_data, openings: u_openings}
    end

    def is_vacant?(%__MODULE__{openings: openings}) do
        (openings |> Enum.count) > 0
    end
end

defmodule ConstHashmap do
    @moduledoc """
    Experimental hashmap implementation with a constant time complexity
    """

    @type t :: %__MODULE__{
        pool: [ConstHashmap.Pool.t]
    }

    defstruct   pool: [%ConstHashmap.Pool{}]

    def format(%__MODULE__{pool: pool}) do
        "%ConstHashmap{\n" 
            <> (Enum.map(pool, &ConstHashmap.Pool.format/1) |> List.to_string)
            <> "}"
    end

    def insert(%__MODULE__{pool: pool}, key, value) do
        pools = ConstHashmap.Tools.modify_cond(pool, &ConstHashmap.Pool.is_vacant?/1, fn e ->
            ConstHashmap.Pool.insert(e, key, value)
        end)
        %__MODULE__{pool: pools}
    end
end

defimpl Inspect, for: ConstHashmap do
    def inspect(hashmap, _opts) do
        ConstHashmap.format(hashmap)
    end
end