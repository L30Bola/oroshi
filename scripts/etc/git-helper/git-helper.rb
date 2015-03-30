module GitHelper

  # Return only --flags
  def get_flag_args(args)
    flags = []
    args.each do |arg|
      flags << arg if arg =~ /^-/
    end
    flags
  end

  # Return only non --flags
  def get_real_args(args)
    real_args = []
    args.each do |arg|
      real_args << arg if arg !~ /^-/
    end
    real_args
  end

  def current_branch
    %x[git branch-current].strip
  end

  def current_remote
    %x[git remote-current].strip
  end

  def current_tag
    %x[git tag-current].strip
  end

  def is_branch(name)
    system("git branch-exists #{name}")
  end

  def is_remote(name)
    system("git remote-exists #{name}")
  end

  def is_tag(name)
    system("git tag-exists #{name}")
  end
  
  def never_pushed?
    system("git branch-remote-status")
    return true if $?.exitstatus == 4
    return false
  end

  def guess_elements(*elements)
    output = {}

    # Guess element types
    elements.each do |element|
      output[:branch] = element if is_branch element
      output[:remote] = element if is_remote element
      output[:tag] = element if is_tag element
    end

    # Set current one as default
    output[:branch] = current_branch if !output[:branch]
    output[:remote] = current_remote if !output[:remote]
    output[:tag] = current_tag if !output[:tag]

    return output
  end



end