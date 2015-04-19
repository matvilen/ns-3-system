# CREATE PLOTS BASED ON TRACE DATA 
########################################################################################################################################
# plot Sequence_alltime
gnuplot << EOF
      set terminal png size 1309,744
      set output "/media/sanek/Seagate/wired/plot/sequence_alltime_$bandwidth$agent.png"
      set title "Sequence_alltime"
      set xtics 30.0
      set xlabel "Time,sec"
      set ylabel "Seqnumber"
      set xr [0:210]
      set yr [0:60000]
      set grid
      plot "data1.dat" using 2:(strcol(1) eq '-' ? \$5: NaN) title "packet was transmitted" with p pt 4 lc rgb "blue" ,\
           "" using 2:(strcol(1) eq 'd' ? \$5: NaN)  title "packet was lost" with p pt 5 lc rgb "red" 
EOF
# plot Sequence_10sec
gnuplot << EOF
      set terminal png size 1309,744
      set output "/media/sanek/Seagate/wired/plot/sequence_10sec_$bandwidth$agent.png"
      set title "Sequence_10sec"
      set key top left
      # set xtics 0.1
      set xlabel "Time,sec"
      set ylabel "Seqnumber"
      set xr [0.5:11]
      set yr [0:60000]
      set grid
      plot "data1.dat" using 2:(strcol(1) eq '-' ? \$5: NaN) title "packet was transmitted" with p pt 4 lc rgb "blue" ,\
	   "" using 2:(strcol(1) eq 'd' ? \$5: NaN)  title "packet was lost" with p pt 5 lc rgb "red"
EOF
# plot Packets transmission over network's cutoff_all
gnuplot << EOF
      set terminal png size 1309,744
      set output "/media/sanek/Seagate/wired/plot/cutoff_all_$bandwidth$agent.png"
      set title "Packets transmission over network's cutoff_all"
      set ytics ("node 0" 0, "node 1" 1, "node 3" 2, "node 2" -1)
      set xlabel "Time,sec"
      set ylabel "Node"
      set xr [0:185]
      set yr [-2:3]
      set grid     
      plot  "data2.dat" using 2:(strcol(1) eq 'd' ? \$3: NaN) title "packet was lost" with p pt 5,\
          "" using 2:(strcol(1) eq '+'| strcol(1) eq '-' | strcol(1) eq'r' ? \$3: NaN) title "packet was transmitted" with lp pt 4 lt 1 lc 3,\
          "" using 2:(strcol(1) eq '-' ? \$3: NaN) title "packet left the queue" with lp pt 4 lt 2
EOF
# Packets transmission over network's cutoff_10sec
gnuplot << EOF
      set terminal png size 1309,744
      set output "/media/sanek/Seagate/wired/plot/cutoff_10sec_$bandwidth$agent.png"
      set title "Packets transmission over network's cutoff_10sec"
      set xtics 1
      set ytics ("node 0" 0, "node 1" 1, "node 3" 2, "node 2" -1)
      set xlabel "Time,sec"
      set ylabel "Node"
      set xr [0:7]
      set yr [-2:3]
      set grid    
      plot  "data2.dat" using 2:(strcol(1) eq 'd' ? \$3: NaN) title "packet was lost" with p pt 5,\
          "" using 2:(strcol(1) eq '+'| strcol(1) eq '-' | strcol(1) eq'r' ? \$3: NaN) title "packet was transmitted" with lp pt 4 lt 1 lc 3,\
          "" using 2:(strcol(1) eq '-' ? \$3: NaN) title "packet left the queue" with lp pt 4 lt 2
EOF
# plot cwnd
gnuplot << EOF
set terminal png size 1309,744
      set output "/media/sanek/Seagate/wired/plot/cwnd_$bandwidth$agent.png"
      set title "CWND"  # set title of plot
      set xlabel "Time,sec"
      set ylabel "CWND"
      set xr [0:185]
      set yr [0:50000]
      set grid
      plot  "cwnd.dat" using 1:2 title "CWND" with p pt 4
EOF