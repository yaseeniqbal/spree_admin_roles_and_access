CanCan::Rule.class_eval do
  def initialize(base_behavior, action = nil, subject = nil, *extra_args, &block)
    @match_all = action.nil? && subject.nil?
    @base_behavior = base_behavior
    @actions = [action].flatten
    @subjects = [subject].flatten
    @attributes = [extra_args.shift].flatten if extra_args.first.kind_of?(Symbol) || extra_args.first.kind_of?(Array) && extra_args.first.first.kind_of?(Symbol)
    raise ::Exception, "You are not able to supply a block with a hash of conditions in #{action} #{subject} ability. Use either one." if extra_args.first.kind_of?(Hash) && !block.nil?
    @conditions = extra_args.first || {}
    @block = block
  end

  # Matches the subject, action, and given attribute. Conditions are not checked here.
  def relevant?(action, subject, attributes=[])
    subject = subject.values.first if subject.class == Hash
    @match_all || (matches_action?(action) && matches_subject?(subject) && matches_attribute?(attributes))
  end

  # Matches the block or conditions hash
  def matches_conditions?(action, subject, attributes=[])
    if @match_all
      call_block_with_all(action, subject)
    elsif @block && !subject_class?(subject)
      @block.arity == 1 ? @block.call(subject) : @block.call(subject, attributes)
    elsif @conditions.kind_of?(Hash) && subject.class == Hash
      nested_subject_matches_conditions?(subject)
    elsif @conditions.kind_of?(Hash) && !subject_class?(subject)
      matches_conditions_hash?(subject)
    else
      # Don't stop at "cannot" definitions when there are conditions.
      @conditions.empty? ? true : @base_behavior
    end
  end

  def attributes?
    @attributes.present?
  end

  private

  def matches_attribute?(attributes=[])
    # don't consider attributes in a cannot clause when not matching - this can probably be refactored
    attributes.compact!
    if !@base_behavior && @attributes && (attributes.nil? || attributes.empty?)
      false
    else
      attributes = if attributes.is_a?(Array)
        attributes.map { |attribute| attribute.try(:to_sym) }.compact!
      else
        attributes.try(:to_sym)
      end
      @attributes.nil? || attributes.nil? || attributes.empty? || ([attributes].flatten - @attributes).empty?
    end
  end
end
