defmodule AddressChecker do
  @moduledoc """
  Documentation for AddressChecker.
  """
  require CSV

  defstruct apartment: "", street: nil, zip: nil, id: 0

  def run() do
    stream_xml()
    |> Stream.chunk_every(5)
    |> Stream.map(&Enum.join(&1, ""))
    |> Stream.map(&build_request/1)
    |> Stream.map(&make_request/1)
    |> Stream.map(&handle_request/1)
    |> Stream.map(&XmlToMap.naive_map/1)
    |> Stream.map(&grab_addresses/1)
    |> Stream.map(fn addresses -> Enum.map(addresses, &grab_address/1) end)
    |> Stream.into(output_stream())
  end

  def output_stream do
    "../out/foo.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
  end

  def grab_addresses(%{"AddressValidateResponse" => %{"Address" => addresses}}),
    do: addresses

  def grab_address(%{
        "Address1" => apartment,
        "Address2" => street,
        "City" => city,
        "ID" => id,
        "State" => state,
        "Zip4" => zip_second,
        "Zip5" => zip_first
      }) do
    id <>
      "," <>
      street <>
      "," <>
      apartment <> "," <> city <> "," <> state <> "," <> zip_first <> "-" <> zip_second <> "\n"
  end

  def grab_address(%{
        "Address2" => street,
        "City" => city,
        "ID" => id,
        "State" => state,
        "Zip4" => zip_second,
        "Zip5" => zip_first
      }) do
    id <>
      "," <>
      street <> "," <> city <> "," <> state <> "," <> zip_first <> "-" <> zip_second <> "\n"
  end

  def build_xml(%AddressChecker{id: id, apartment: apt, street: street, zip: zip}) do
    EEx.eval_file("assets/template.eex",
      id: id,
      apartment: apt,
      street: street,
      zip: zip
    )
  end

  def stream_xml() do
    "../assets/address_list/musts.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Stream.map(&build_map/1)
    |> Stream.map(&build_xml/1)
    |> Stream.map(&strip_returns/1)
    |> Stream.map(&URI.encode/1)
  end

  def make_request(string) do
    string
    |> HTTPoison.get()
  end

  def handle_request({:ok, %HTTPoison.Response{body: body}}) do
    body
  end

  def handle_request({:error, error}) do
    error
  end

  def build_request(string) do
    "http://production.shippingapis.com/ShippingAPI.dll?API=Verify&XML=" <>
      URI.encode("<AddressValidateRequest USERID=\"415KORMI2286\">") <>
      string <> URI.encode("</AddressValidateRequest>")
  end

  def strip_returns(string) do
    string
    |> String.replace(~r/\n\W*</, "<")
  end

  def build_map({:ok, %{"Address 1" => street, "Address 2" => apt, "Zip" => zip, "id" => id}}),
    do: %AddressChecker{apartment: apt, street: street, zip: zip, id: id}
end
