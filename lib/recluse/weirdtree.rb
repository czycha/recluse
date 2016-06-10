module Recluse
	##
	# Sorta like a node tree but using two hashes for easy searching.
	class WeirdTree
		def initialize
			@parent_keys = {}
			@child_keys = {}
		end
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
		def add_parent(parents)
			[*parents].each do |parent|
				@parent_keys[parent] = [] unless @parent_keys.has_key?(parent)
			end
		end
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
		def set_child_value(child, value)
			@child_keys[child][:value] = value
		end
		def get_child_value(child)
			@child_keys[child][:value]
		end
		def get_parents(child)
			@child_keys[child][:parents]
		end
		def get_children(parent)
			@parent_keys[parent]
		end
		def get_values(parent)
			vals = {}
			@parent_keys[parent].each do |child|
				vals[child] = @child_keys[child][:value]
			end
			return vals
		end
		def parents(as_hash: true)
			if as_hash
				@parent_keys.dup
			else
				@parent_keys.keys
			end
		end
		def children(as_hash: true)
			if as_hash
				@child_keys.dup
			else
				@child_keys.keys
			end
		end
		def has?(element)
			@parent_keys.has_key?(element) or @child_keys.has_key?(element)
		end
		def has_child?(element)
			@child_keys.has_key?(element)
		end
		def has_parent?(element)
			@parent_keys.has_key?(element)
		end
	end
end