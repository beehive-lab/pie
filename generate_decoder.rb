=begin

This file is part of PIE, an instruction encoder / decoder generator:
    https://github.com/beehive-lab/pie

Copyright 2011-2016 Cosmin Gorgovan <cosmin at linux-geek dot org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end

require './generate_common.rb'

class Node
  attr_accessor :depth, :instruction, :left, :right
  @depth
  @value
  @left
  @right
end

def generate_f_prot(insts, c_ptr)
  print "#{ARGV[0]}_instruction #{ARGV[0]}_decode(#{c_ptr} *address)"
end

def generate_header(insts, inst_len)
  puts "#ifndef __#{ARGV[0].upcase}_PIE_DECODER_H__"
  puts "#define  __#{ARGV[0].upcase}_PIE_DECODER_H__"
  puts "#include <stdint.h>"
  puts "typedef enum {"
  insts.each do |inst|
    puts "  #{ARGV[0].upcase}_#{inst[:name].upcase},"
  end
  puts "  #{ARGV[0].upcase}_INVALID"  
  puts "} #{ARGV[0]}_instruction;"
  generate_f_prot(insts, inst_len_to_cptr(inst_len))
  puts ";"
  puts "#endif"
end

def build_tree(instructions, bit)
  if (instructions.size == 0)
    return nil
  end
  
  if (instructions.size == 1 and instructions[0][:bitmap].rindex(/0|1/) < bit)
    node = Node.new
    node.depth = bit
    node.instruction = instructions[0]
    return node
  end
  
  #terminate after scanning the whole instruction word
  if (bit >= instructions[0][:bitmap].size)
    most_specific = 0
    i = nil
    instructions.each do |instruction|
      count = instruction[:bitmap].count("01")
      if count > most_specific
        most_specific = count
        i = instruction
      end
    end
    
    node = Node.new
    node.depth = bit
    
    node.instruction = i
    return node
  end
  
  progress = false
  max_word_length = get_max_inst_len(instructions)
  while (bit < max_word_length and !progress)
    left = []
    right = []
  
    instructions.each do |instruction|
      if (instruction[:bitmap][bit] == '0')
        left.push(instruction)
        progress = true
      elsif (instruction[:bitmap][bit] == '1')
        right.push(instruction)
        progress = true
      elsif (instruction[:bitmap][bit].match(/[a-z]/))
        left.push(instruction)
        right.push(instruction)
      else
        warn max_word_length
        warn instructions.inspect
        abort "Unknown bit value in bit #{bit} in " + instruction[:bitmap] + " in " + instruction[:name]
      end
    end
    
    bit += 1
  end
  
  node = Node.new
  node.depth = bit
  node.left =  build_tree(left, bit)
  node.right = build_tree(right, bit)
  return node
end

def indent(depth)
 (0..depth).each do |i|
    print "  "
  end
end

def generate_c(node, depth, def_inst_width, sub)
  indent(depth)
  if (node == nil)
    puts "return #{ARGV[0].upcase}_INVALID;"
    return
  end
  if (node.instruction)
    puts "// #{node.instruction[:bitmap].gsub(/[a-z]/, 'x')}"
    indent(depth)
    puts "return #{ARGV[0].upcase}_#{node.instruction[:name].to_s.upcase};"
    return
  end
  
  if ((node.depth - sub) > def_inst_width)
    puts "instruction = *(++address);"
    sub += def_inst_width
    indent(depth)
  end
  puts "if ((instruction & (1 << #{(def_inst_width - (node.depth - sub))})) == 0) {"
  generate_c(node.left, depth+1, def_inst_width, sub)
  indent(depth)
  puts "} else {"
  generate_c(node.right, depth+1, def_inst_width, sub)
  indent(depth)
  puts "}"
end

def generate_decoder(insts, inst_len)
  c_ptr = inst_len_to_cptr(inst_len)
  puts "#include \"pie-#{ARGV[0]}-decoder.h\"\n\n"
  generate_f_prot(insts, c_ptr)
  puts " {"
  puts "  #{c_ptr} instruction = *address;"
  tree = build_tree(insts, 0)
  generate_c(tree, 0, inst_len, 0)
  puts "}"
end

insts = process_insts(ARGV[0] + ".txt")

inst_len = get_min_inst_len(insts)

if (ARGV[1] and ARGV[1] == "header")
  generate_header(insts, inst_len)
else
  generate_decoder(insts, inst_len)
end

