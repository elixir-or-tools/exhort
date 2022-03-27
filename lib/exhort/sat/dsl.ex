defmodule Exhort.SAT.DSL do
  @moduledoc false

  # An expression-based DSL for specifying variables and constraints.

  alias Exhort.SAT.LinearExpression

  @doc """
  Transform the DSL AST expression into representative model-based expressions.
  """
  def transform_expression(expression_ast) do
    transform(expression_ast)
  end

  defp transform({:<<>>, _, _} = str) do
    quote do
      unquote(str)
    end
  end

  defp transform({:*, _, [x, y]}) do
    quote do
      LinearExpression.prod(unquote(transform(x)), unquote(transform(y)))
    end
  end

  defp transform({:+, _, [x, y]}) do
    quote do
      LinearExpression.sum(unquote(transform(x)), unquote(transform(y)))
    end
  end

  defp transform({:-, _, [x, y]}) do
    quote do
      LinearExpression.minus(unquote(transform(x)), unquote(transform(y)))
    end
  end

  defp transform({:sum, _, [args]}) do
    quote do
      LinearExpression.sum(unquote(transform(args)))
    end
  end

  defp transform({:not, _, [args]}) do
    quote do
      LinearExpression.bool_not(unquote(transform(args)))
    end
  end

  defp transform([head | []]), do: [transform(head)]
  defp transform([head | tail]), do: [transform(head) | transform(tail)]

  defp transform({:if, x}), do: {:if, transform(x)}
  defp transform({:unless, x}), do: {:unless, transform(x)}

  defp transform({:for, m, list}), do: {:for, m, transform(list)}
  defp transform({:<-, m, list}), do: {:<-, m, transform(list)}
  defp transform({:do, arg}), do: {:do, transform(arg)}

  defp transform(i), do: i
end
