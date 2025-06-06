# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# contributed by jose fco. gonzalez
# modified by Sokolov Yura
# Parallelism by Rick Branson

$seq = String.new

def frequency(seq, length)
  frequencies = Hash.new(0)
  ns          = seq.length + 1 - length

  for i in (0...ns)
    frequencies[seq[i, length]] += 1
  end

  [ns, frequencies]
end

def sort_by_freq(seq, length)
  ret       = ''
  n, table  = frequency(seq, length)

  table.sort { |a, b| b[1] <=> a[1] }.each do |v|
    ret += format("%s %.3f\n", v[0].upcase, (v[1] * 100).to_f / n)
  end

  ret += "\n"
end

def find_seq(seq, s)
  _, table = frequency(seq, s.length)
  "#{table[s]}\t#{s.upcase}\n"
end

line = STDIN.gets while line !~ /^>THREE/
line = STDIN.gets
while (line !~ /^>/) & line
  $seq << line.chomp
  line = STDIN.gets
end

class Worker
  def initialize
    @r, @w = IO.pipe
    @p = Process.fork do
      @r.close
      @w.write yield
      @w.close
    end

    @w.close
  end

  def result
    ret = @r.read
    @r.close
    Process.wait(@p)
    ret
  end
end

FREQS   = [1, 2]
NUCLEOS = %w[ggt ggta ggtatt ggtattttaatt ggtattttaatttatagt]

workers =   FREQS.map   { |i| Worker.new { sort_by_freq($seq, i) } }
workers +=  NUCLEOS.map { |s| Worker.new { find_seq($seq, s) } }

results = workers.map { |w| w.result }
print results.join
