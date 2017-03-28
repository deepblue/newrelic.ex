defmodule NewRelic.Plug.ErrorHandler do
  defmacro __using__(_env) do
    quote do
      def call(conn, opts) do
        t_conn = NewRelic.Plug.Phoenix.register_transaction(conn)

        try do
          super(t_conn, opts)
        catch
          kind, reason ->
            Plug.ErrorHandler.__catch__(t_conn, kind, reason, &handle_errors/2)
        end
      end

      defp handle_errors(conn, %{reason: %FunctionClauseError{function: :do_match}} = ex), do: nil
      defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{}} = ex), do: nil
      defp handle_errors(conn, %{kind: _kind, reason: exception, stack: stack}) do
        with {:ok, transaction} <- Map.fetch(conn.private, :new_relixir_transaction) do
          NewRelic.Transaction.record_error(transaction, exception, inspect(stack))
        end
      end
    end
  end
end
