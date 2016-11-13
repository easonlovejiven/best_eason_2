if Rails.env.production?
  segment_key = 'rvVUt7FHZLGRvM7f7DFThwxEWgT8pyJ4'
else
  segment_key = 'sSuAVJ2Y93PLO3D988ob9xmbjxNCYHGX'
end

Analytics = Segment::Analytics.new({
    write_key: segment_key,
    on_error: Proc.new { |status, msg| print msg }
})
