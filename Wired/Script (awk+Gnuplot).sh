#!/bin/bash
# КОМАНДА ВЫЗОВА
# bash tigraph1.sh DataModel.tr rx.dat

# следующий скрипт выводит данные из трассы по столбцам:
# (r|+|-|d) время узел узел:интерфейс Seq length UNKNOWN ip1:ip2
	awkfilterscript='BEGIN { seqnf=0; lennf=0; payloadnf=0; addressnf=0; seq=-1; payload=-1; len=-1; address=-1;} 
((seqnf==0)?1:($seqnf !~ /Seq/)) { seqnf=0; for (i=1;i<NF;i++) if ($i ~ /Seq/) seqnf=i; }
((payloadnf==0)?1:($payloadnf !~ /Payload/)) { payload=-1; payloadnf=0; for (i=1;i<NF;i++) if ($i ~ /Payload/) payloadnf=i+1; } 
((lennf==0)?1:($lennf !~ /length/)) { len=-1; lennf=0; for (i=1;i<NF;i++) if ($i ~ /length/) lennf=i+1; }
((addressnf==0)?1:($addressnf !~ /length/)) {address=-1; addressnf=0; for (i=1;i<NF;i++) if ($i ~ /length/) addressnf=i+2;}
(seqnf>0) { seq=-1; sub(/.*=/,"",$seqnf); seq=$seqnf; } 
(payloadnf>0) { sub(/.*=/,"",$payloadnf); sub(/\)/,"",$payloadnf); payload=$payloadnf; } 
(lennf>0) { len = $lennf; } 
(addressnf != 0) {address = $addressnf}
{ print $1, $2, $3, $4, seq, len, 1, address }'

# данные скрипты используются для выделения отдельных участков трассы
	# этими скриптами задаем интересующий нас промежуток времени
	mintimescript='{if ($2 >= mintime) {print $0}'
	maxtimescript='{if ($2 <= maxtime) {print $0}}'

	# этими скриптами задаем min и max размеры пакетов 
	minpayloadscript='{if ($7 >= minpayload) {print $0}}'
	maxpayloadscript='{if ($7 <= maxpayload) {print $0}}'
	
	# этими скриптами задаем min и max значение Sequence
	minseqscript='{if ($8 == ip12) {if ($5 >= minseq) {print $0}} else {print $0}}'
	maxseqscript='{if ($8 == ip12) {if ($5 <= maxseq) {print $0}} else {print $0}}'
	
	# пока не нужен 
	#delscript='{if (/./ || /^tr/) {print $0;}}'

# CUTOFF
# следующими скриптами фильтруем нашу трассу таким образом, чтобы далее вывести на экран изображение интересующего нас среза сети
	# скрипт, который группирует данные трассы по значению Sequence
	# вызов: awk "$awkseparatescript"
	awkseparatescript='(($5 != prev)) {print "\n"; prev=$5;} {print $0;}'

	# скрипт, разделяющий данные по пункту назначения передачи (по ip1->ip2)
	# вызов: awk "$awkidentifyscript"
	awkidentifyscript='($8 != prev) { print "transmission " $8; prev=$8} {print $0}'
	
	# с помощью данного скрипта мы располагаем узлы на графике так, как нам удобнее всего (частный случай, когда на срезе 4 узла)
	# вызов awk "$railroadscript"
	railroadscript='{if ($3 == "2") {$3 = -1} else if ($3 == "3") {$3 = 2} {print $0}}'

	# с помощью данного скрипта мы выделяем отдельно случаи, когда пакет был потерян при передаче
	# вызов awk "$droppacketscript"
	droppacketsscript='{ if ($1 == "d") {print $0; print "\n";} else {print $0}}'
	
	# еще один скрипт, фильтрующий данные так как нам необходимо
	# вызов awk "$separate2"
	separate2='{if ($3 == "2") {print $0; print "\n";} else {print $0;}}'



# ВЫЧИСЛЕНИЕ GOODPUT
#	dscript='BEGIN {retransmitted=0; send=0;} {if ($1 == "d") {retransmitted=retransmitted+1;}} {if ($1 == "-") {send=send+1;}} END {print  (send-retransmitted) }'

# ВЫЧИСЛЕНИЕ FIRELESS INDEX
#	fiscript='BEGIN {r1=0;r2=0;r3=0;r4=0;r5=0;r6=0;r7=0;r8=0;r9=0;r10=0;r11=0;s1=0;s2=0;s3=0;s4=0;s5=0;s6=0;s7=0;s8=0;s9=0;s10=0;s11=0;} 
#	{ 
#		if ($3 == "2") { {if ($1 == "d") {r1=r1+1;}} {if ($1 == "-") {s1=s1+1;}}} else 
#		if ($3 == "4") { {if ($1 == "d") {r2=r2+1;}} {if ($1 == "-") {s2=s2+1;}}} else 
#		if ($3 == "5") { {if ($1 == "d") {r3=r3+1;}} {if ($1 == "-") {s3=s3+1;}}} else
#		if ($3 == "6") { {if ($1 == "d") {r4=r4+1;}} {if ($1 == "-") {s4=s4+1;}}} else 
#		if ($3 == "7") { {if ($1 == "d") {r5=r5+1;}} {if ($1 == "-") {s5=s5+1;}}} else 
#		if ($3 == "8") { {if ($1 == "d") {r6=r6+1;}} {if ($1 == "-") {s6=s6+1;}}} else 
#		if ($3 == "9") { {if ($1 == "d") {r7=r7+1;}} {if ($1 == "-") {s7=s7+1;}}} else 
#		if ($3 == "10") { {if ($1 == "d") {r8=r8+1;}} {if ($1 == "-") {s8=s8+1;}}} else
#		if ($3 == "11") { {if ($1 == "d") {r9=r9+1;}} {if ($1 == "-") {s9=s9+1;}}} else 
#		if ($3 == "12") { {if ($1 == "d") {r10=r10+1;}} {if ($1 == "-") {s10=s10+1;}}} else 
#		if ($3 == "13") { {if ($1 == "d") {r11=r11+1;}} {if ($1 == "-") {s11=s11+1;}} 
#		} 
#	}
#	{ g1=(s1-r1); g2=(s2-r2); g3=(s3-r3); g4=(s4-r4); g5=(s5-r5); g6=(s6-r6); g7=(s7-r7); g8=(s8-r8); g9=(s9-r9); g10=(s10-r10); g11=(s11-r11);
#	} END {print ((g1+g2+g3+g4+g5+g6+g7+g8+g9+g10+g11)^2)/(11*(g1^2+g2^2+g3^2+g4^2+g5^2+g6^2+g7^2+g8^2+g9^2+g10^2+g11^2))}'


# данный скрипт оставляет только строки, хранящий информации именно о передаче пакета
	lenscript='{if ($6 > 300) {print $0}}'

# данный скрипт используется для лучшего(более удобного) представления данных на графике sequence
	modscript='{$5 = $5%60000} {if ($3 == "2") {print $0}}'



###############################################################################################################################################
# НАЧАЛО ВЫПОЛНЕНИЯ СКРИПТА
###############################################################################################################################################
ns3=ns3::
for (( c=0; c<3; c++ ))
do
count=0
if [ $c == '0' ]; then
agent=TcpReno
agentgf="<tr><td>TCP Reno</td>"
agentrx="<tr><td>TCP Reno</td>"
elif [ $c == '1' ]; then 
agent=TcpNewReno
agentgf="<tr><td>TCP New Reno</td>"
agentrx="<tr><td>TCP New Reno</td>"
elif [ $c == '2' ]; then 
agent=TcpTahoe
agentgf="<tr><td>TCP Tahoe</td>"
agentrx="<tr><td>TCP Tahoe</td>"
fi
headgf="<table border="1" cellpadding="4" cellspacing="0">
               <caption>Comparative table of TCP agents's goodput&Fairness Index</caption>
			<tr>
				<td>Agent/Rate</td>"
headrx="<table border="1" cellpadding="4" cellspacing="0">
               <caption>Comparative table of TCP agents's Rx</caption>
			<tr>
				<td>Agent/Rate</td>"
for (( i=1; i<10; i++ ))
do
echo "<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
 <htmL>
 <head>
 <title>
 $agent
 </title>
 </head>
 <body>"
for (( j=0; j<=9; j++ ))
do
bandwidth=$i.$j
Mbps=Mbps
headgf="$headgf <td>$i.$j Mbit/s</td>"
headrx="$headrx <td>$i.$j Mbit/s</td>"
let "count=$count+1"
echo "<h1>Experiment $count.</h1>"
echo "<h2>"Agent: $agent"</h2>"
echo "<h3>Rate=$i.$j megabits</h3>"
echo "<h3>"
# запускаем нашу модель сети с параметрами bandwidth и agent
./waf --run="modelFinal_wired --bandwidth0=$bandwidth$Mbps --agent=$ns3$agent"
echo "</h3>"

##############################################################################################################################################
# SEQUENCE -- ФИЛЬТР ДАННЫХ ПО ИНТЕРЕСУЮЩИМ СРЕЗАМ СЕТИ (для построения графика sequence) 
cat $1 | sed -e 's/\/[0-9][0-9]*/&&/' -e 's/\/NodeList\///' -e 's/\// /' -e 's/\/DeviceList\//:/' -e 's/\/\$ns[a-zA-Z0-9/\:]*//' -e 's/ > /:/' -e 's/)/ /g' | awk "$awkfilterscript" | awk "$lenscript" | awk "$modscript" > data1.dat

# CUTOFF -- ФИЛЬТР ДАННЫХ ПО ИНТЕРЕСУЮЩИМ СРЕЗАМ СЕТИ (для построения графика cutoff)
cat $1 | sed -e 's/\/[0-9][0-9]*/&&/' -e 's/\/NodeList\///' -e 's/\// /' -e 's/\/DeviceList\//:/' -e 's/\/\$ns[a-zA-Z0-9/\:]*//' -e 's/ > /:/' -e 's/)/ /g' | awk "$awkfilterscript" | awk "$lenscript" | grep -e 10.0.0.11:10.0.1.11 | sed -e '/^.\s[0-9]\./s/[0-9]\./00&/' -e '/^.\s[0-9][0-9]\./s/[0-9][0-9]\./0&/' | awk "$railroadscript" | sort -k8 -k5 -k2 | awk "$awkidentifyscript" | awk "$awkseparatescript" | awk "$droppacketsscript" | awk "$separate2" > data2.dat

# GOODPUT (ВЫЧИСЛЯЕМ ЗНАЧЕНИЕ GOODPUT)
echo "<h3> Goodput= "
goodput=`cat $2 | awk 'END {print $3*8/180 , "bits/s"}'`
echo $goodput
echo "</h3>"

# FAIRNESS INDEX (ВЫЧИСЛЯЕМ ЗНАЧЕНИЕ FAIRNESS INDEX)
echo "<h3> Fairness index= "
findex=`cat $2 | awk '{print $3 , $3*$3}' | awk '{ sum += $1; sum2 += $2;} END {print sum-$1 , sum2-$2;}' | awk '{print $1*$1/(10*$2)}'`
echo $findex
echo "</h3>"

# RX (ВЫЧИСЛЯЕМ ЗНАЧЕНИЕ RX)
echo "<h3>"
rx=`cat $2`
echo $rx
echo "</h3>"
##############################################################################################################################################

agentgf="$agentgf <td>$goodput / $findex</td>"
agentrx="$agentrx <td>$rx</td>"

########################################################################################################################################
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
################################################################################################################################################

################################################################################################################################################
# HTML-code. THERE WE ADD ALL PLOTS IN HTML-file
################################################################################################################################################
echo "<h2>
	    <p align="center">
	       <font color="red" face="Arial">
		Plots
	       </font>
	    </p>
      </h2>
      <h2>
	     1.<img src=\"plot/sequence_alltime_$bandwidth$agent.png\">
      </h2>
             <p align="center">Fig. 1. Experimental results of the protocol $agent (investigated characteristic: <u>sequence&time</u>)</p>
      <h2>
	     2.<img src=\"plot/sequence_10sec_$bandwidth$agent.png\">
      </h2> 
             <p align="center">Fig. 1. Experimental results of the protocol $agent (investigated characteristic: <u>sequence&time</u>)</p>
      <h2>
	     3.<img src=\"plot/cutoff_all_$bandwidth$agent.png\">
      </h2>
             <p align="center">Fig. 1. Experimental results of the protocol $agent (investigated characteristic: <u>Packets transmission over network's cutoff</u>)</p>
      <h2>
	     4.<img src=\"plot/cutoff_10sec_$bandwidth$agent.png\">
      </h2>
             <p align="center">Fig. 1. Experimental results of the protocol $agent (investigated characteristic: <u>Packets transmission over network's cutoff</u>)</p>
      <h2>
	     5.<img src=\"plot/cwnd_$bandwidth$agent.png\">
      </h2>
             <p align="center">Fig. 1. Experimental results of the protocol $agent (investigated characteristic: <u>CWND</u>)</p>"

################################################################################################################################################

################################################################################################################################################
# CREATE ARCHIVE OF TRACE DATA
################################################################################################################################################
  SRCDIR="DataModel.tr"
  DESTDIR="/media/sanek/Seagate/wired/Archive/"
  FILENAME="trace_$agent-$bandwidth-Mbps.tgz"
  tar --create --gzip --file=$DESTDIR$FILENAME $SRCDIR
################################################################################################################################################

done
echo "</body>
      </html>"
done > "/media/sanek/Seagate/wired/$agent.html"
headgf="$headgf </tr>"
headrx="$headrx </tr>"
agentgf="$agentgf </tr>"
agentrx="$agentrx </tr>"
if [ $c == '0' ]; then 
echo $headgf > "/media/sanek/Seagate/wired/gf.html"
echo $headrx > "/media/sanek/Seagate/wired/rx.html"
fi
echo $agentgf >> "/media/sanek/Seagate/wired/gf.html"
echo $agentrx >> "/media/sanek/Seagate/wired/rx.html"
done
echo "</table>" >> "/media/sanek/Seagate/wired/gf.html"
echo "</table>" >> "/media/sanek/Seagate/wired/rx.html"

