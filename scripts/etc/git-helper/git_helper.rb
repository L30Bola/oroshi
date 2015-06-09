require 'shellwords'
require 'English'

# Allow access to current git repository state
module GitHelper
  @@colors = {
    branch: 202,
    branch_bugfix: 203,
    branch_develop: 184,
    branch_feature: 202,
    branch_fix: 203,
    branch_gh_pages: 24,
    branch_master: 69,
    branch_perf: 141,
    branch_release: 171,
    branch_review: 28,
    branch_test: 136,
    hash: 67,
    message: 250,
    remote: 202,
    remote_github: 24,
    remote_heroku: 141,
    remote_origin: 184,
    remote_upstream: 69,
    remote_algolia: 67,
    tag: 241,
    url: 250,
    valid: 35
  }

  def color(type)
    @@colors[type]
  end

  def branch_color(branch)
    color_symbol = ('branch_' + branch).to_sym
    return @@colors[color_symbol] if @@colors[color_symbol]
    @@colors[:branch]
  end

  def remote_color(remote)
    color_symbol = ('remote_' + remote).to_sym
    return @@colors[color_symbol] if @@colors[color_symbol]
    @@colors[:remote]
  end

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
    replace_short_aliases real_args
  end

  def replace_short_aliases(elements)
    elements.map do |element|
      next 'develop' if element == 'd'
      next 'github' if element == 'gh'
      next 'heroku' if element == 'h'
      next 'master' if element == 'm'
      next 'origin' if element == 'o'
      next 'release' if element == 'r'
      next 'upstream' if element == 'u'
      element
    end
  end

  def push_pull_indicator(branchName)
    system("git branch-remote-status #{branchName}")
    code = $CHILD_STATUS.exitstatus
    return ' ' if code == 1
    return ' ' if code == 2
    return ' ' if code == 3
    return ' ' if code == 4
  end

  def colorize(text, color)
    color = format('%03d', color)
    "[38;5;#{color}m#{text}[00m"
  end

  def longest_by_type(list, type)
    ordered = list.map { |obj| obj[type] }.group_by(&:size)
    return nil if ordered.size == 0
    ordered.max.last[0]
  end

  def submodule?(path)
    system("git-is-submodule #{path.shellescape}")
  end

  def repo_root
    `git root`.strip
  end

  def current_branch
    `git branch-current`.strip
  end

  def current_remote
    `git remote-current`.strip
  end

  def current_tag
    `git tag-current`.strip
  end

  def current_tags
    tags = `git tag-current-all`.strip.split("\n")
    tags << current_tag
    tags.uniq
  end

  def branch?(name)
    system("git branch-exists #{name}")
  end

  def remote?(name)
    system("git remote-exists #{name}")
  end

  def tag?(name)
    system("git tag-exists #{name}")
  end

  def never_pushed?
    system('git branch-remote-status')
    return true if $CHILD_STATUS.exitstatus == 4
    false
  end

  def guess_elements(elements)
    output = {}

    # Guess element types
    elements.each do |element|
      output[:branch] = element if branch? element
      output[:remote] = element if remote? element
      output[:tag] = element if tag? element
    end

    # Set current one as default
    output[:branch] = current_branch unless output[:branch]
    output[:remote] = current_remote unless output[:remote]
    output[:tag] = current_tag unless output[:tag]

    # If still no remote, we default to origin
    output[:remote] = 'origin' if output[:remote] == ''

    output
  end
end