defmodule AddressCheckerTest do
  use ExUnit.Case
  doctest AddressChecker

  test "builds xml from full input address" do
    addr = %{apartment: "Apartment A", street: "2113 Carpenter Street", zip: 19146}

    assert AddressChecker.build_xml(0, input_address: addr) ==
             """
             <AddressValidateRequest USERID="415KORMI2286">
               <Address ID="#{0}">
                 <Address1>#{addr.apartment}</Address1>
                 <Address2>#{addr.street}</Address2>
                 <City></City>
                 <State></State>
                 <Zip5>#{addr.zip}</Zip5>
                 <Zip4></Zip4>
               </Address>
             </AddressValidateRequest>
             """
             |> String.trim()
  end

  test "builds xml from input address with no apartment" do
    addr = %{street: "2113 Carpenter Street", zip: 19146, apartment: ""}

    assert AddressChecker.build_xml(0, input_address: addr) ==
             """
             <AddressValidateRequest USERID="415KORMI2286">
               <Address ID="#{0}">
                 <Address1></Address1>
                 <Address2>#{addr.street}</Address2>
                 <City></City>
                 <State></State>
                 <Zip5>#{addr.zip}</Zip5>
                 <Zip4></Zip4>
               </Address>
             </AddressValidateRequest>
             """
             |> String.trim()
  end
end
