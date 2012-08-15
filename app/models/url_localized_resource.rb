class UrlLocalizedResource < LocalizedResource

  def play_command_for play_resource_command
    play_resource_command.play_url_command_for self
  end

  def capture_resource_for play_resource_command, session
    play_resource_command.url_capture_resource_for self, session
  end
end
