defmodule H2Integration.Helpers.SetupHelper do
  alias Sparrow.H2Worker.Config, as: Config

  def child_spec(opts) do
    args = opts[:args]
    name = opts[:name]

    id = :rand.uniform(100_000)

    %{
      :id => id,
      :start => {Sparrow.H2Worker, :start_link, [name, args]}
    }
  end

  def cowboys_name() do
    :look
  end

  defp current_dir() do
    System.cwd()
  end

  def create_h2_worker_config(
        address \\ Setup.server_host(),
        port \\ 8080,
        args \\ [],
        timeout \\ 10_000
      ) do
    Config.new(address, port, args, timeout)
  end

  defp certificate_settings_list() do
    [
      {:cacertfile, current_dir() <> "/priv/ssl/fake_cert.pem"},
      {:certfile, current_dir() <> "/priv/ssl/fake_cert.pem"},
      {:keyfile, current_dir() <> "/priv/ssl/fake_key.pem"}
    ]
  end

  defp settings_list(:positive_cerificate_verification, port) do
    [
      {:port, port},
      {:verify, :verify_peer},
      {:verify_fun, {fn _, _, _ -> {:valid, :ok} end, :ok}}
    ] ++ certificate_settings_list()
  end

  defp settings_list(:negative_cerificate_verification, port) do
    [
      {:port, port},
      {:verify, :verify_peer},
      {:verify_fun, {fn _, _, _ -> {:fail, :negative_cerificate_verification} end, :ok}}
    ] ++ certificate_settings_list()
  end

  defp settings_list(:no, port) do
    [
      {:port, port}
    ] ++ certificate_settings_list()
  end

  def start_cowboy_tls(dispatch_config, cerificate_required \\ :no, port \\ 8080, name \\ :look) do
    settings_list = settings_list(cerificate_required, port)

    {:ok, pid} =
      :cowboy.start_tls(
        name,
        settings_list,
        %{:env => %{:dispatch => dispatch_config}}
      )

    {:ok, pid, name}
  end

  def server_host() do
    "localhost"
  end

  def default_headers() do
    [
      {"accept", "*/*"},
      {"accept-encoding", "gzip, deflate"},
      {"user-agent", "chatterbox-client/0.0.1"}
    ]
  end
end