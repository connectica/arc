defmodule Arc.Actions.Store do
  @version_timeout 100000 #milliseconds

  defmacro __using__(_) do
    quote do
      def store(args), do: Arc.Actions.Store.store(__MODULE__, args)
    end
  end

  def store(definition, {file, scope}) when is_binary(file) or is_map(file) do
    put(definition, {Arc.File.new(file), scope})
  end

  def store(definition, filepath) when is_binary(filepath) or is_map(filepath) do
    store(definition, {filepath, nil})
  end

  #
  # Private
  #

  defp put(definition, {{:error, msg}, scope}) do
    {:error, :invalid_file}
  end

  defp put(definition, {%Arc.File{}=file, scope}) do
    case definition.validate({file, scope}) do
      true ->
        scope = Dict.put(scope, :sub_folder, gen_subfolder)
        put_versions(definition, {file, scope})
        {:ok, file.file_name, scope.sub_folder}
      _ -> {:error, :invalid_file}
    end
  end

  defp gen_subfolder, do: UUID.uuid1()
  defp put_versions(definition, {file, scope}) do
    definition.__versions
    |> Enum.map(fn(r) -> async_put_version(definition, r, {file, scope}) end)
    |> Enum.each(fn(task) -> Task.await(task, @version_timeout) end)
  end

  defp async_put_version(definition, version, {file, scope}) do
    Task.async(fn ->
      put_version(definition, version, {file, scope})
    end)
  end

  defp put_version(definition, version, {file, scope}) do
    file = Arc.Processor.process(definition, version, {file, scope})
    file_name = Arc.Definition.Versioning.resolve_file_name(definition, version, {file, scope})
    file = %Arc.File{file | file_name: file_name}
    definition.__storage.put(definition, version, {file, scope})
  end
end
