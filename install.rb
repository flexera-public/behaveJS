def copy_asset(name)
  destination = File.join(RAILS_ROOT, "public/javascripts", name)
  source      = File.join(File.dirname(__FILE__) , "assets", name)
  FileUtils.cp_r(source, destination)
end

puts "Copying Javascript assets..."
copy_asset("behaveJS.js")
copy_asset("behaveJS_application.js")
puts "Done. behaveJS is now installed."