defmodule ArcTest.Actions.Url do
  use ExUnit.Case, async: false
  import Mock

  defmodule DummyDefinition do
    use Arc.Actions.Url

    def __versions, do: [:original, :thumb]
    def default_url(version), do: "dummy-#{version}"
    def __storage, do: Arc.Storage.S3
  end

  test "delegates default_url generation to the definition when given a nil file" do
    assert DummyDefinition.url(nil) == "dummy-original"
    assert DummyDefinition.url(nil, :thumb) == "dummy-thumb"
    assert DummyDefinition.url({nil, :scope}, :thumb) == "dummy-thumb"
  end

  test_with_mock "delegates url generation to the storage engine", Arc.Storage.S3,
    [url: fn(DummyDefinition, :original, {%{file_name: "file.png"}, nil}, []) -> :ok end] do
    assert DummyDefinition.url("file.png") == :ok
  end

  test_with_mock "optional atom as a second argument specifies the version", Arc.Storage.S3,
    [url: fn(DummyDefinition, :thumb, {%{file_name: "file.png"}, nil}, []) -> :ok end] do
    assert DummyDefinition.url("file.png", :thumb) == :ok
  end

  test_with_mock "optional list as a second argument specifies the options", Arc.Storage.S3,
    [url: fn(DummyDefinition, :original, {%{file_name: "file.png"}, nil}, [signed: true, expires_in: 10]) -> :ok end] do
    assert DummyDefinition.url("file.png", signed: true, expires_in: 10) == :ok
  end

  test_with_mock "optional tuple for file including scope", Arc.Storage.S3,
    [url: fn(DummyDefinition, :original, {%{file_name: "file.png"}, :scope}, []) -> :ok end] do
    assert DummyDefinition.url({"file.png", :scope}) == :ok
  end

  test_with_mock "optional tuple for file including scope 2", Arc.Storage.S3,
    [url: fn
    (DummyDefinition, :original, {%{file_name: "file.png"}, :scope}, [signed: true]) -> :ok
    (DummyDefinition, :thumb, {%{file_name: "file.png"}, :scope}, [signed: true]) -> :ok
  end] do
    assert DummyDefinition.urls({"file.png", :scope}, signed: true) == %{original: :ok, thumb: :ok}
  end
end
