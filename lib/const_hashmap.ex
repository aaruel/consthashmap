defmodule ConstHashmap.Element do
    @type t :: %__MODULE__{
        key: any(),
        value: any(),
        collision_pool: ConstHashmap.Pool.t | nil
    }

    defstruct   key: nil,
                value: nil,
                collision_pool: nil

    def format(%__MODULE__{key: key, value: value, collision_pool: collision_pool}) do
        if collision_pool do
            ConstHashmap.Pool.format(collision_pool)
        end
        "    " <> inspect(key) <> ": " <> inspect(value) <> "\n"
    end
    
    def insert(
        %__MODULE__{key: o_key, value: o_value, collision_pool: collision_pool}, 
        key, value, hash_level
    ) do
        if o_key == key do
            %__MODULE__{
                key: o_key,
                value: value,
                collision_pool: collision_pool
            }
        else
            %__MODULE__{
                key: o_key, 
                value: o_value, 
                collision_pool: ConstHashmap.Pool.insert(
                    ConstHashmap.Pool.new(hash_level + 1),
                    key,
                    value
                )
            }
        end
    end

    def get(
        %__MODULE__{value: o_value, key: o_key, collision_pool: collision_pool}, 
        key
    ) do
        if o_key == key do
            o_value
        else
            if collision_pool do
                ConstHashmap.Pool.get(collision_pool, key)
            else
                nil
            end
        end
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

    def hash(key, mask_size, hash_level) do
        pad_size = mask_size * hash_level
        <<_pad :: size(pad_size), hk :: size(mask_size), _data :: bitstring>> = :crypto.hash(:sha256, inspect(key))
        hk
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
                data: ConstHashmap.Tools.two_power_data(@power_size),
                hash_level: 0

    def new(hash_level) when is_integer(hash_level) do
        %__MODULE__{hash_level: hash_level}
    end

    def format(%__MODULE__{data: data, openings: openings}) do
        occupied = @standard_openings -- openings
        Enum.map(occupied, fn index -> 
            elem(data, index) |> ConstHashmap.Element.format
        end) |> List.to_string
    end

    def insert(%__MODULE__{data: data, openings: openings, hash_level: hash_level}, key, value) do
        hash_index = ConstHashmap.Tools.hash(key, @power_size, hash_level)
        u_openings = Enum.filter(openings, fn n -> n != hash_index end)
        u_data = case elem(data, hash_index) do
            %ConstHashmap.Element{key: nil} -> 
                new_elem = %ConstHashmap.Element{key: key, value: value}
                put_elem(data, hash_index, new_elem)
            element -> 
                new_elem = ConstHashmap.Element.insert(element, key, value, hash_level)
                put_elem(data, hash_index, new_elem)
        end
        %__MODULE__{data: u_data, openings: u_openings}
    end

    def get(%__MODULE__{data: data, hash_level: hash_level}, key) do
        hash_index = ConstHashmap.Tools.hash(key, @power_size, hash_level)
        IO.inspect(elem(data, hash_index))
        case elem(data, hash_index) do
            %ConstHashmap.Element{key: nil} -> 
                nil
            element -> 
                ConstHashmap.Element.get(element, key)
        end
    end
end

defmodule ConstHashmap do
    @moduledoc """
    Experimental hashmap implementation with a constant time complexity
    """

    @type t :: %__MODULE__{
        pool: ConstHashmap.Pool.t
    }

    defstruct   pool: %ConstHashmap.Pool{}

    def format(%__MODULE__{pool: pool}) do
        "%ConstHashmap{\n" 
            <> (pool |> ConstHashmap.Pool.format)
            <> "}"
    end

    def insert(%__MODULE__{pool: pool}, key, value) do
        %__MODULE__{pool: ConstHashmap.Pool.insert(pool, key, value)}
    end

    def get(%__MODULE__{pool: pool}, key) do
        ConstHashmap.Pool.get(pool, key)
    end
end

defimpl Inspect, for: ConstHashmap do
    def inspect(hashmap, _opts) do
        ConstHashmap.format(hashmap)
    end
end