module Recluse
  ##
  # Sorta like a node tree but using two hashes for easy searching for parents and/or children.
  # This way, it should have similar performance whether you're iterating over parents or children.
  # Additionally, not every child will need a parent or they might not need a parent at initialization.
  class HashTree
    ##
    # Create a hash tree.
    def initialize(&block)
      @parent_keys = {}
      @child_keys = {}
      @equivalence = block.nil? ? (proc { |a, b| a == b }) : block
    end

    ##
    # Add child associated with parent(s).
    def add(child, parents)
      unless child?(child)
        @child_keys[child] = {
          value: nil,
          parents: []
        }
      end
      @child_keys[get_child_key(child)][:parents] += [*parents]
      [*parents].each do |parent|
        @parent_keys[parent] = [] unless parent?(parent)
        @parent_keys[get_parent_key(parent)] << get_child_key(child)
      end
    end

    ##
    # Add parent with no children.
    def add_parent(parents)
      [*parents].each do |parent|
        @parent_keys[parent] = [] unless parent?(parent)
      end
    end

    ##
    # Add child with no value and no parents.
    def add_child(children)
      [*children].each do |child|
        next if child?(child)
        @child_keys[child] = {
          value: nil,
          parents: []
        }
      end
    end

    ##
    # Set value of child.
    def set_child_value(child, value)
      @child_keys[get_child_key(child)][:value] = value
    end

    ##
    # Get value of child.
    def get_child_value(child)
      @child_keys[get_child_key(child)][:value]
    end

    ##
    # Get child's parents
    def get_parents(child)
      @child_keys[get_child_key(child)][:parents]
    end

    ##
    # Get parent's children
    def get_children(parent)
      @parent_keys[get_parent_key(parent)]
    end

    ##
    # Collect values of children for parent.
    def get_values(parent)
      vals = {}
      @parent_keys[get_parent_key(parent)].each do |child|
        vals[child] = @child_keys[child][:value]
      end
      vals
    end

    ##
    # Get parents hash.
    def parents
      @parent_keys.dup
    end

    ##
    # Get children hash.
    def children
      @child_keys.dup
    end

    ##
    # Does element exist as a child and/or parent key?
    def has?(element)
      child?(element) || parent?(element)
    end

    ##
    # Is element a child?
    def child?(element)
      @child_keys.keys.any? { |key| @equivalence.call(key, element) }
    end

    ##
    # Is element a parent?
    def parent?(element)
      @parent_keys.keys.any? { |key| @equivalence.call(key, element) }
    end

    ##
    # Delete child. Removes references to child in associated parents.
    def delete_child(element)
      return false unless child?(element)
      c_key = get_child_key(element)
      @child_keys[c_key][:parents].each do |parent|
        @parent_keys[parent] -= [c_key]
      end
      @child_keys.delete c_key
      true
    end

    ##
    # Delete parent. Removes references to parent in associated children.
    def delete_parent(element)
      return false unless parent?(element)
      p_key = get_parent_key(element)
      @parent_keys[p_key].each do |child|
        @child_keys[child][:parents] -= [p_key]
      end
      @parent_keys.delete p_key
      true
    end

    ##
    # Delete from parents and children. Essentially removes all known references.
    def delete(element)
      delete_child(element)
      delete_parent(element)
    end

    ##
    # Finds children without parents. Returned as hash.
    def orphans
      @child_keys.select { |_key, info| info[:parents].empty? }
    end

    ##
    # Finds parents without children. Returned as hash.
    def childless
      @parent_keys.select { |_key, children| children.empty? }
    end

    private

    ##
    # Get the child key (in case of alternative equivalence testing)
    def get_child_key(child)
      @child_keys.keys.find { |key| @equivalence.call(key, child) }
    end

    ##
    # Get the parent key (in case of alternative equivalence testing)
    def get_parent_key(parent)
      @parent_keys.keys.find { |key| @equivalence.call(key, parent) }
    end
  end
end
