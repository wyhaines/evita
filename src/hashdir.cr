require "digest/sha256"

# This is a standalone utility that can be used to hash the contents of
# a directory, including all subdirectories.

dir = File.expand_path(ARGV[0]? ? ARGV[0] : ".")
digest = Digest::SHA256.new
Dir["#{dir}/**"].each do |f|
  begin
    digest.file(f) unless File.readable?(f) && File.directory?(f)
  rescue e : Exception
    # Ah, just silently swallow errors.
  end
end

puts digest.final.hexstring
