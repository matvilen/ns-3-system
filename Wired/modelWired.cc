#include "ns3/core-module.h"
#include "ns3/global-route-manager.h"
#include "ns3/bridge-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
#include "ns3/csma-helper.h"

using namespace ns3;

#define EXP_NNODES 10

class MyApp : public Application 
{
public:

  MyApp ();
  virtual ~MyApp();

  void Setup (Ptr<Socket> socket, Address address, uint32_t packetSize, uint32_t nPackets, DataRate dataRate);

private:
  virtual void StartApplication (void);
  virtual void StopApplication (void);

  void ScheduleTx (void);
  void SendPacket (void);

  Ptr<Socket>     m_socket;
  Address         m_peer;
  uint32_t        m_packetSize;
  uint32_t        m_nPackets;
  DataRate        m_dataRate;
  EventId         m_sendEvent;
  bool            m_running;
  uint32_t        m_packetsSent;
};

MyApp::MyApp ()
  : m_socket (0), 
    m_peer (), 
    m_packetSize (0), 
    m_nPackets (0), 
    m_dataRate (0), 
    m_sendEvent (), 
    m_running (false), 
    m_packetsSent (0)
{
}

MyApp::~MyApp()
{
  m_socket = 0;
}

void
MyApp::Setup (Ptr<Socket> socket, Address address, uint32_t packetSize, uint32_t nPackets, DataRate dataRate)
{
  m_socket = socket;
  m_peer = address;
  m_packetSize = packetSize;
  m_nPackets = nPackets;
  m_dataRate = dataRate;
}

void
MyApp::StartApplication (void)
{
  m_running = true;
  m_packetsSent = 0;
  m_socket->Bind ();
  m_socket->Connect (m_peer);
  SendPacket ();
}

void 
MyApp::StopApplication (void)
{
  m_running = false;

  if (m_sendEvent.IsRunning ())
    {
      Simulator::Cancel (m_sendEvent);
    }

  if (m_socket)
    {
      m_socket->Close ();
    }
}

void 
MyApp::SendPacket (void)
{
  Ptr<Packet> packet = Create<Packet> (m_packetSize);
  m_socket->Send (packet);

  if (++m_packetsSent < m_nPackets)
    {
      ScheduleTx ();
    }
}

void 
MyApp::ScheduleTx (void)
{
  if (m_running)
    {
      Time tNext (Seconds (m_packetSize * 8 / static_cast<double> (m_dataRate.GetBitRate ())));
      m_sendEvent = Simulator::Schedule (tNext, &MyApp::SendPacket, this);
    }
}

static void
CwndChange (Ptr<OutputStreamWrapper> stream, uint32_t oldCwnd, uint32_t newCwnd)
{
  *stream->GetStream () << Simulator::Now ().GetSeconds () << "\t" << oldCwnd << "\t" << newCwnd << std::endl;
}

int main(int argc, char *argv[])
{
    std::string bandwidth0  = "1Mbps";
    std::string agent = "ns3::TcpReno";
    uint32_t segment = 1600;
    uint32_t queue = 25;
    CommandLine cmd;
    cmd.AddValue ("bandwidth0", "Enter the bandwidth of the bottleneck node", bandwidth0);
    cmd.AddValue ("agent", "Enter TCP agent", agent);
    cmd.AddValue ("segment", "Enter size of the segment", segment);
    cmd.AddValue ("queue", "Enter size of the queue", queue);
    cmd.Parse (argc, argv);
    
    /* the general configuration of the experiment */
    // Packet size in the experiment
    Config::SetDefault ("ns3::OnOffApplication::PacketSize", UintegerValue (1500));
    //std::string tcpModel ("ns3::TcpNewReno");
    //Config::SetDefault ("ns3::TcpL4Protocol::SocketType", StringValue (tcpModel));
    // Max size of queue in the nodes
    Config::SetDefault("ns3::DropTailQueue::MaxPackets", UintegerValue (queue));
    // Segment size in the experiment
    Config::SetDefault("ns3::TcpSocket::SegmentSize", UintegerValue (segment));
    
    /* Create nodes in our network */

    /* Topology:
       TCP Sources          TCP Sinks
       N4                   N14
       ... \             /  ...
       N13 -- N0 --- N1 --  N23
           /             \
       N2                   N3 */

    NodeContainer p2pNodes; // Here are N0 and N1 nodes
    p2pNodes.Create (2);
    NodeContainer srcNode; // Here is N2 node
    srcNode.Create (1);
    NodeContainer sinkNode; // Here  is N3 node
    sinkNode.Create (1);
    NodeContainer N_Sources; // Here are all left-side nodes
    N_Sources.Create (EXP_NNODES);
    N_Sources.Add(srcNode.Get(0));
    N_Sources.Add(p2pNodes.Get(0));
    NodeContainer N_Sinks; // Here are all right-side nodes
    N_Sinks.Create (EXP_NNODES);
    N_Sinks.Add(sinkNode.Get(0));
    N_Sinks.Add(p2pNodes.Get(1));
    
    
    /* Create channels */
    // Channel N0 --- N1
    PointToPointHelper p2p;
    p2p.SetDeviceAttribute ("DataRate", StringValue (bandwidth0));
    p2p.SetChannelAttribute ("Delay",  TimeValue (MilliSeconds (105)));
    NetDeviceContainer p2pDevices;
    p2pDevices = p2p.Install(p2pNodes);
    // Subnetworks N0  N1
    CsmaHelper N0csma, N1csma;
    N0csma.SetChannelAttribute("DataRate", StringValue("100Mbps"));
    N0csma.SetChannelAttribute("Delay", TimeValue(MilliSeconds(10)));
    N1csma.SetChannelAttribute("DataRate", StringValue("100Mbps"));
    N1csma.SetChannelAttribute("Delay", TimeValue(MilliSeconds(10)));
    
    NetDeviceContainer N0devices, N1devices;
    N0devices = N0csma.Install(N_Sources);
    N1devices = N1csma.Install(N_Sinks);
    
    /* Install the IP stack. */
    Config::SetDefault ("ns3::TcpL4Protocol::SocketType", StringValue ("ns3::TcpNewReno")); // TCP New Reno in all sockets by default
    InternetStackHelper stack;
    stack.Install(N_Sources);
    stack.Install(N_Sinks);
    
    /* IP assign. */
    Ipv4AddressHelper ipv4;
    ipv4.SetBase ("10.0.0.0", "255.255.255.0");
    Ipv4InterfaceContainer iface_lefts = ipv4.Assign (N0devices);
    ipv4.SetBase ("10.0.1.0", "255.255.255.0");
    Ipv4InterfaceContainer iface_rights = ipv4.Assign (N1devices);
    ipv4.SetBase ("10.0.2.0", "255.255.255.0");
    Ipv4InterfaceContainer iface_p2p = ipv4.Assign (p2pDevices);
    
    /* Generate Route. */
    Ipv4GlobalRoutingHelper::PopulateRoutingTables ();
    
    /* Experiment */
    TypeId tid = TypeId::LookupByName(agent);
    std::stringstream nId;
    nId << srcNode.Get(0)->GetId();
    std::string specificNode = "/NodeList/"+nId.str()+"/$ns3::TcpL4Protocol/SocketType";
    Config::Set(specificNode, TypeIdValue(tid));
      Ptr<Socket> ns3TcpSocket =  Socket::CreateSocket(srcNode.Get(0), TcpSocketFactory::GetTypeId());

    nId.str(std::string());
    nId << sinkNode.Get(0)->GetId();
    specificNode = "/NodeList/"+nId.str()+"/$ns3::TcpL4Protocol/SocketType";
    Config::Set(specificNode, TypeIdValue(tid));
    Socket::CreateSocket(sinkNode.Get(0), TcpSocketFactory::GetTypeId());
    
    /* Generate Application. */
    uint16_t app_port = 49100;
    
    ApplicationContainer apps;
    OnOffHelper onoff = OnOffHelper("ns3::TcpSocketFactory", InetSocketAddress(Ipv4Address("10.0.0.0"), app_port));
    onoff.SetAttribute("OnTime", StringValue("ns3::ConstantRandomVariable[Constant=1]"));
    onoff.SetAttribute("OffTime", StringValue("ns3::ConstantRandomVariable[Constant=0]"));
    // Organize Data Streams
    for (uint32_t i = 0; i<EXP_NNODES; i++) {
        std::stringstream oss;
        oss << "10.0.1." << (i+1);
        onoff.SetAttribute("Remote", AddressValue(InetSocketAddress(Ipv4Address(oss.str().c_str()), app_port)));
        //onoff.SetAttribute("PacketSize", StringValue("1024"));
        onoff.SetAttribute("DataRate", StringValue("40Mbps"));
        onoff.SetAttribute("StartTime", TimeValue(Seconds(0)));
        onoff.SetAttribute("StopTime", TimeValue(Seconds(60)));        
	apps = onoff.Install(N_Sources.Get(i));
	if (i < EXP_NNODES)
	{
	//onoff.SetAttribute("PacketSize", StringValue("1024"));
        onoff.SetAttribute("DataRate", StringValue("40Mbps"));
        onoff.SetAttribute("StartTime", TimeValue(Seconds(120)));
        onoff.SetAttribute("StopTime", TimeValue(Seconds(180)));
        apps = onoff.Install(N_Sources.Get(i));
	}
    }
    Address sinkAddress (InetSocketAddress (iface_rights.GetAddress (10), app_port));
    PacketSinkHelper sink = PacketSinkHelper("ns3::TcpSocketFactory", InetSocketAddress(Ipv4Address::GetAny(), app_port));
    apps = sink.Install(N_Sinks);
    apps.Start(Seconds(0.0));
    
    Ptr<MyApp> app = CreateObject<MyApp> ();
    app->Setup (ns3TcpSocket, sinkAddress, 1500, 10000000 , DataRate ("100Mbps"));
    srcNode.Get (0)->AddApplication (app);
    app->SetStartTime (Seconds (0.0));
    app->SetStopTime (Seconds (180.0));

    /* Simulation. */
    AsciiTraceHelper ascii;
    N0csma.EnableAsciiAll (ascii.CreateFileStream ("DataModel.tr"));
    AsciiTraceHelper asciiTraceHelper;
    Ptr<OutputStreamWrapper> stream = asciiTraceHelper.CreateFileStream ("cwnd.dat");
    ns3TcpSocket->TraceConnectWithoutContext ("CongestionWindow", MakeBoundCallback (&CwndChange, stream));
    /* Stop the simulation after x seconds. */
    uint32_t stopTime = 180;
    Simulator::Stop (Seconds (stopTime));
    /* Start and clean simulation. */
    Simulator::Run ();

    std::ofstream outputFile;
    outputFile.open("rx.dat");
    Ptr<PacketSink> pktsink;
    for (uint32_t i=0; i<=EXP_NNODES; i++) {
        pktsink = apps.Get(i)->GetObject<PacketSink> ();
        //std::cout << "Rx(" << i << ") = " << pktsink->GetTotalRx() << " bytes; ";
	if (i == EXP_NNODES)
	{
	outputFile << "Rx(" << i << ") = " << pktsink->GetTotalRx() << " bytes. " << "\n";	
	} else
        outputFile << "Rx(" << i << ") = " << pktsink->GetTotalRx() << " bytes; " << "\n";
    }
    std::cout << std::endl;
    
    Simulator::Destroy ();
}
