# Pure transform: merged avionics data + a link id -> a WireViz YAML doc (Hash).
# Kept separate from the CLI so it is unit-testable without running wireviz.

def wireviz_color(c)
  c.to_s.gsub("/", "").upcase   # "WH/BU" -> "WHBU"; WireViz-native 2-letter codes
end

def find_connector(data, box_id, conn_id)
  data.each do |_name, section|
    next unless section.is_a?(Hash) && section["boxes"]
    section["boxes"].each do |b|
      next unless b["id"] == box_id
      b["connectors"].each { |c| return [b, c] if c["id"] == conn_id }
    end
  end
  [nil, nil]
end

def find_link(data, link_id)
  data.each do |_name, section|
    next unless section.is_a?(Hash) && section["links"]
    section["links"].each { |l| return l if l["id"] == link_id }
  end
  nil
end

def build_wireviz_doc(data, link_id)
  link = find_link(data, link_id) or raise "unknown link #{link_id}"
  doc = { "connectors" => {}, "cables" => {}, "connections" => [], "additional_components" => [] }

  # Connectors: one per node, pinlabels from the box connector definition.
  link["nodes"].each do |n|
    _box, conn = find_connector(data, n["box"], n["connector"])
    raise "missing #{n['box']}.#{n['connector']}" unless conn
    key = "#{n['box']}.#{n['connector']}"
    pins = conn["pins"].keys.sort_by { |p| p.to_s.to_i }
    doc["connectors"][key] = {
      "pinlabels" => pins.map { |p| conn["pins"][p]["signal"] },
      "pins" => pins,
    }
  end

  # Cable: the shared wire set.
  doc["cables"][link_id] = {
    "wirecount" => link["wires"].length,
    "gauge" => link["gauge"] ? "#{link['gauge']} AWG" : nil,
    "colors" => link["wires"].map { |w| wireviz_color(w["color"]) },
  }.compact

  # Connections: chain the cable through every node (daisy = multi-connector set).
  signals = link["wires"].map { |w| w["signal"] }
  set = []
  link["nodes"].each_with_index do |n, i|
    pins = signals.map { |s| n["pins"][s] }
    set << { "#{n['box']}.#{n['connector']}" => pins }
    set << { link_id => (1..signals.length).to_a } unless i == link["nodes"].length - 1
  end
  doc["connections"] << set

  # Inline components -> WireViz additional_components (drawn + BOM).
  (link["components"] || []).each do |c|
    doc["additional_components"] << {
      "type" => "#{c['type']} #{c['value']}".strip,
      "qty" => 1,
    }
  end

  doc
end