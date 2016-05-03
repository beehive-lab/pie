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

def process_insts(filename)
  process_file(filename, true)
end

def process_all(filename)
  process_file(filename, false)
end

def process_file(filename, insts_only = false)
  insts = []

  File.readlines(filename).each do |line|
    if line.strip.empty?
      break if insts_only
      next
    end
    line = line.split(/[, ]+/)
    
    inst = Hash.new
    inst[:name] = line[0]

    inst[:bitmap] = ""
    i = 1
    while (line[i] and !line[i].include?(':'))
      inst[:bitmap] += line[i].strip
      i += 1
    end

    inst[:fields] = {}
    (i...line.size).each do |i|
      field = line[i].split(':')
      inst[:fields][field[0]] = field[1].strip
    end
 
    insts.push inst
  end
  
  return insts
end

def inst_len_to_cptr(len)
  case len
    when 16
      c_ptr = "uint16_t"
    when 32
      c_ptr = "uint32_t"
    else
      abort "Unknown instruction word width: #{len}"
  end
  return c_ptr
end

def get_min_inst_len(insts)
  min = 99999
  insts.each do |inst|
    min = inst[:bitmap].size if inst[:bitmap].size < min
  end
  return min
end

def get_max_inst_len(insts)
  max = 0
  insts.each do |inst|
    max = inst[:bitmap].size if inst[:bitmap].size > max
  end
  return max
end

def get_field_shift(bitmap, label)
  bitmap.size - bitmap.rindex(label) - 1
end

def get_field_mask(bitmap, label)
  width = bitmap.rindex(label) - bitmap.index(label) + 1
  return "0x" + ((1 << width) -1).to_s(16)
end
