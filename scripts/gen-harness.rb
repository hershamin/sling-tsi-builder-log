#!/usr/bin/env ruby
# View C generator: _data/avionics/*.yml -> WireViz YAML -> SVG in assets/img/avionics/.
# Requires `wireviz` (pip install wireviz) + Graphviz on PATH for the render step.
require "yaml"
require "fileutils"
require_relative "gen_harness_lib"

ROOT = File.expand_path("..", __dir__)
OUT  = File.join(ROOT, "assets", "img", "avionics")
TMP  = File.join(ROOT, ".avionics-wireviz")

data = {}
Dir[File.join(ROOT, "_data", "avionics", "*.yml")].each do |f|
  data[File.basename(f, ".yml")] = YAML.load_file(f)
end

link_ids = data.values.flat_map { |s| (s.is_a?(Hash) && s["links"]) ? s["links"].map { |l| l["id"] } : [] }
abort "no links found" if link_ids.empty?

FileUtils.mkdir_p(OUT)
FileUtils.mkdir_p(TMP)
have_wireviz = system("which wireviz > /dev/null 2>&1")

link_ids.each do |id|
  doc = build_wireviz_doc(data, id)
  yml = File.join(TMP, "#{id}.yml")
  File.write(yml, doc.to_yaml)
  puts "wrote #{yml}"
  next unless have_wireviz

  system("wireviz", yml) or warn "wireviz failed for #{id}"
  %w[svg png html].each do |ext|
    src = File.join(TMP, "#{id}.#{ext}")
    FileUtils.mv(src, File.join(OUT, "#{id}.#{ext}")) if File.exist?(src)
  end
end

puts have_wireviz ? "Harness SVGs in #{OUT}" : "WireViz not installed — wrote WireViz YAML to #{TMP} only. Install wireviz to render SVGs."
