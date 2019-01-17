CanCan::Ability.module_eval do
  def relevant_rules(action, subject, attributes=[])
    rules.reverse.select do |rule|
      rule.expanded_actions = expand_actions(rule.actions)
      rule.relevant? action, subject, attributes
    end
  end

  def relevant_rules_for_match(action, subject, attributes=[])
    relevant_rules(action, subject, attributes).each do |rule|
      if rule.only_raw_sql?
        raise ::Exception, "The can? and cannot? call cannot be used with a raw sql 'can' definition. The checking code cannot be determined for #{action.inspect} #{subject.inspect}"
      end
    end
  end

  def can?(action, subject, *attributes)
    match = relevant_rules_for_match(action, subject, attributes).detect do |rule|
      rule.matches_conditions?(action, subject, attributes)
    end
    match ? match.base_behavior : false
  end

  def can(*args, &block)
    rules << CanCan::Rule.new(true, *args, &block)
  end

  def cannot(*args, &block)
    rules << CanCan::Rule.new(false, *args, &block)
  end
end
