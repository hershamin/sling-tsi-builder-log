require "minitest/autorun"
require_relative "gen_harness_lib"

class TestBuildWireviz < Minitest::Test
  def data
    {
      "config" => { "functions" => { "can" => "#1f77b4" } },
      "nav" => {
        "boxes" => [
          { "id" => "pfd", "connectors" => [{ "id" => "J1", "pins" => { 1 => { "signal" => "CAN-H" }, 2 => { "signal" => "CAN-L" } } }] },
          { "id" => "gps", "connectors" => [{ "id" => "P1", "pins" => { 5 => { "signal" => "CAN-H" }, 6 => { "signal" => "CAN-L" } } }] },
        ],
      },
      "buses" => {
        "links" => [{
          "id" => "can_main", "function" => "can", "topology" => "daisy", "gauge" => 22,
          "wires" => [{ "signal" => "CAN-H", "color" => "WH/BU" }, { "signal" => "CAN-L", "color" => "WH/OR" }],
          "nodes" => [
            { "box" => "pfd", "connector" => "J1", "pins" => { "CAN-H" => 1, "CAN-L" => 2 } },
            { "box" => "gps", "connector" => "P1", "pins" => { "CAN-H" => 5, "CAN-L" => 6 } },
          ],
          "components" => [{ "type" => "resistor", "value" => "120Ω", "across" => ["CAN-H", "CAN-L"], "at" => "pfd" }],
        }],
      },
    }
  end

  def test_builds_doc_for_can_main
    doc = build_wireviz_doc(data, "can_main")
    assert doc["connectors"].key?("pfd.J1"), "expected pfd.J1 connector"
    assert doc["connectors"].key?("gps.P1"), "expected gps.P1 connector"
    assert doc["cables"].key?("can_main"), "expected can_main cable"
    assert_equal ["WHBU", "WHOR"], doc["cables"]["can_main"]["colors"], "colors stripped of slash"
    assert_equal 2, doc["cables"]["can_main"]["wirecount"]
    # daisy chain expressed as connector -> cable -> connector in connections
    flat = doc["connections"].flatten.map(&:to_s).join(" ")
    assert_includes flat, "pfd.J1"
    assert_includes flat, "gps.P1"
    # terminator captured as an additional component
    assert(doc["additional_components"].any? { |c| c["type"].include?("resistor") }, "expected resistor component")
  end
end