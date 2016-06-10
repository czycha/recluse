module Recluse
	##
	# Sorta like a node tree but using two hashes for easy searching for parents and/or children.
	class WeirdTree
		##
		# Create a weird tree.
		def initialize
			@parent_keys = {}
			@child_keys = {}
		end

		##
		# Add child associated with parent(s).
		def add(child, parents)
			unless @child_keys.has_key?(child)
				@child_keys[child] = {
					:value => nil,
					:parents => []
				}
			end
			@child_keys[child][:parents] += [*parents]
			[*parents].each do |parent|
				@parent_keys[parent] = [] unless @parent_keys.has_key?(parent)
				@parent_keys[parent] << child
			end
		end

		##
		# Add parent with no children.
		def add_parent(parents)
			[*parents].each do |parent|
				@parent_keys[parent] = [] unless @parent_keys.has_key?(parent)
			end
		end

		##
		# Add child with no value and no parents.
		def add_child(children)
			[*children].each do |child|
				unless @child_keys.has_key?(child)
					@child_keys[child] = {
						:value => nil,
						:parents => []
					}
				end
			end
		end

		##
		# Set value of child.
		def set_child_value(child, value)
			@child_keys[child][:value] = value
		end

		##
		# Get value of child.
		def get_child_value(child)
			@child_keys[child][:value]
		end

		##
		# Get child's parents
		def get_parents(child)
			@child_keys[child][:parents]
		end

		##
		# Get parent's children
		def get_children(parent)
			@parent_keys[parent]
		end

		##
		# Collect values of children for parent.
		def get_values(parent)
			vals = {}
			@parent_keys[parent].each do |child|
				vals[child] = @child_keys[child][:value]
			end
			return vals
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
			@parent_keys.has_key?(element) or @child_keys.has_key?(element)
		end

		##
		# Is element a child?
		def has_child?(element)
			@child_keys.has_key?(element)
		end

		##
		# Is element a parent?
		def has_parent?(element)
			@parent_keys.has_key?(element)
		end
	end
end