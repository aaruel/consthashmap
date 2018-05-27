defmodule ConstHashmap.Element do
    @type t :: %__MODULE__{
        value: any(),
        reference_index: non_neg_integer() | nil
    }

    defstruct   value: nil,
                reference_index: nil
end

defmodule ConstHashmap.Tools do
    defp generate_nsize_list(size, element, list \\ []) when is_integer(size) do
        list = list ++ [element]
        if size > 0 do
            generate_nsize_list(size - 1, element, list)
        else
            list
        end
    end

    def two_power_openings(power) when is_integer(power) do
        0..(:math.pow(2, power) - 1 |> trunc) |> Enum.to_list
    end

    def two_power_data(power) when is_integer(power) do
        list = generate_nsize_list(:math.pow(2, power) |> trunc, %ConstHashmap.Element{})
        list |> List.to_tuple
    end
end

defmodule ConstHashmap.Pool do
    require ConstHashmap.Tools

    @type t :: %__MODULE__{
        openings: [non_neg_integer()],
        data: {ConstHashmap.Element.t}
    }

    defstruct   openings: ConstHashmap.Tools.two_power_openings(3),
                data: ConstHashmap.Tools.two_power_data(3)
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
        "{\n" <> 
    end
end

defimpl Inspect, for: ConstHashmap do
    def inspect(hashmap, _opts) do
        ConstHashmap.format(hashmap)
    end
end