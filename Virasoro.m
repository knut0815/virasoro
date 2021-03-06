(* ::Package:: *)

(*All functions in this package make free usage of the notation defined in 1703.09727, such as b, h, V, q, z, etc.*)
(*Typical usage would be to invoke some runs, either using VRun or running from C++ and reading the resulting file with VRead. Then you will likely want to analyze the results with the plotting and analysis functions at the bottom.*)

BeginPackage["Virasoro`"]

(*Return version of package being accessed*)
VVersionCheck::usage = "VVersionCheck[] returns the number and date of the loaded version of Virasoro.m.";

(*For simple computations*)
VGethmn::usage = "VGethmn[m_,n_,b_] gives degenerate Virasoro operator dimension h_mn at the given b.";
VGet\[Lambda]sq::usage = "VGet\[Lambda]sq[p_,q_,b_] gives square of internal \[Lambda]_pq at the given b.";
VGet\[Lambda]::usage = "VGet\[Lambda][p_,q_,b_] gives internal \[Lambda]_pq at the given b.";
VGetBsq::usage = "VGetBsq[c_] gives b^2 corresponding to the given c.";
VGetC::usage = "VGetC[bsq_] gives c corresponding to the given b^2.";

(*For plotting in Lorentzian time*)
VEKMono::usage = "VEKMono[r_,tL_] gives the EllipticK[z] for these parameters with some modifications to account for the monodromy.";
VqVal::usage = "VqVal[r_,tL] gives the q value corresponding to the given Lorentzian time tL using radius r.";
VVofZ::usage = "VVofZ[z_,coeVec_,c_,hL_,hH_,maxOrder_] gives the Virasoro block V at coordinate z, using the coefficients of q^{mn} contained in coeVec.";
VVofT::usage = "VVofT[coeVec_,c_,hL_,hH_,hp_,r_,tL_,maxOrder_] gives the Lorentzian Virasoro block approximated by the coefficients of q^{mn} in coeVec at Lorentzian time tL.";
VSemiClassical::usage = "VSemiClassical[c_,hL_,hH_,r_,tL_] gives the value of the semiclassical approximation of the vacuum block at Lorentzian time tL with radius r.";
VSemiOfZ::usage = "VSemiOfZ[c_,hL_,hH_,z_] gives the value of the semiclassical vacuum block at z_.";
VDegenBlock12::usage = "VDegenBlock12[c_,hL_,hh_,r_,tL_] gives the exact degenerate h_12 vacuum block at time tL and radius r.";
VDegenBlock21::usage = "VDegenBlock21[c_,hL_,hh_,r_,tL_] gives the exact degenerate h_21 vacuum block at time tL and radius r.";

(*For generating, reading, and writing results from virasoro batch runs*)
VRun::usage = "VRun[c_, hl_, hh_, hp_, maxOrder_] or VRun[{c, hl, hh, hp, maxOrder}] computes the coefficients for the given parameter set(s) and returns them as a list of lists using the same format as VRead."
VRunFromFile::usage = "VRunFromFile[filename_] or simply VRun[filename_] invokes a C++ run from the named runfile and returns the results.";
VLengthCheck::usage = "VLengthCheck[filename_] gives the length of the result vector contained in filename.";
VRead::usage = "VRead[filename_] gives the results of the C++ run stored in filename as a vector of vectors of numbers, ready to be used in Mathematica.";
VWrite::usage = "VWrite[results_,filename_] writes results to a file with the given filename in such a way that they can be read back later with VRead.";

(*For plotting and analysis*)
VMakePlotLabel::usage = "VMakePlotLabel[results_,runNumber_] is an internal function that returns a list of parameters used in a run. This is put at the top of most plots.";
VPlotCoeffs::usage = "VPlotCoeffs[results_,n_:0(,Options\[Rule]Value)] gives a log-log plot of the raw coefficients of run n in the given array; n=0 plots all runs. Options StartingRun, EndingRun, and RunStep specified as Option\[Rule]Value.";
VPlot::usage = "VPlot[results_,n_:0(,Option\[Rule]Value)] plots Virasoro blocks from the n_th run stored in results_ as a function of Lorentzian time, using radius r_. n=0 plots all runs in the array, with runStep>1 allowing you to skip runs.

Options are specified as in Wolfram's Plot[]: Option\[Rule]Value, e.g. EndTime\[Rule]40. Options are PlotScale (\"Linear\", \"SemiLog\", or \"LogLog\"), StartTime, EndTime, PointsPerTL, StartingRun, EndingRun, RunStep, and Compare. Setting Compare\[Rule]\"Semi\" compares to semiclassical vacuum block; other possibilities are \"12\" and \"21\" which compare to exact degenerate blocks.";
VConvByOrder::usage = "VConvByOrder[results_,tL_(,Option\[Rule]Value)] gives plots showing how adding more terms to each run in results_ improves the convergence at particular radius r_ and Lorentzian time tL_.

Options are specified as in Wolfram's Plot[]: Option\[Rule]Value, e.g. StartingRun\[Rule]10. Options are StartingRun, RunStep, and EndingRun.";
VConvByTL::usage = "VConvByTL[results_(,Option\[Rule]Value)] gives plots showing how the convergence of the last few orders of each run in results_ varies with tL at a given r_.

Options are specified as in Wolfram's Plot[]: Option\[Rule]Value, e.g. StartingRun\[Rule]10. Options are StartingRun, RunStep, EndingRun, StartTime, and EndTime.";
VFindEndTimes::usage = "VFindEndTimes[results_(,OptionV\[Rule]Value)] gives the latest time after before which the full block and the block with 10 fewer terms differ by at most 5%.

Options are specified as in Wolfram's Plot[]: Option\[Rule]Value, e.g. StartingRun\[Rule]10. Options are StartingRun, RunStep, EndingRun, StartTime, EndTime, r, and Bins.";
VConvByQ::usage = "VConvByQ[results_(,Option\[Rule]Value)] gives plots showing how the convergence of the last few orders of each run in results_ varies with q.

Options are specified as in Wolfram's Plot[]: Option\[Rule]Value, e.g. StartingRun\[Rule]10. Options are StartingRun, RunStep, EndingRun.";
VZMap::usage = "VZMap[results_] shows a contour plot of V in the complex z plane.";
VDepTime::usage = "VDepTime[results_] finds the time when the exact block in results_ divided by the semiclassical block is always >= 1.1.

The required ratio can be changed with Ratio->#.";

Begin["VirasoroInternal`"]
VVersionCheck[]:=Module[{versionNumber,versionDate},
versionNumber="1.0.3";
versionDate="2017-10-20";
Print["The currently loaded version of Virasoro.m is "<>
versionNumber<>", published "<>versionDate<>"."];
];

VGethmn[m_,n_,b_]:=b^2*(1-n^2)/4+(1-m^2)/(4*b^2)+(1-m*n)/2;
VGet\[Lambda]sq[p_,q_,b_]:=4*VGethmn[p,q]-(b+1/b)^2;
VGet\[Lambda][p_,q_,b_]:=Sqrt[VGet\[Lambda]sq[p,q,b]];
VGetBsq[c_]:=(-13+c+Sqrt[25-26c+c^2])/12;
VGetC[bsq_]:=13+6*(bsq+1/bsq);

VEKMono[r_,tL_]:=EllipticK[1-r*Exp[-I*tL]]-2*I*(1+Floor[(-tL-\[Pi])/(2\[Pi])]) EllipticK[r*Exp[-I*tL]];
VqVal[r_,tL_]:=Exp[-\[Pi]*EllipticK[r*Exp[-I*tL]]/VEKMono[r,tL]];
VVofZ[z_,coeVec_,c_,hL_,hH_,hp_,maxOrder_]:=Module[{q,V},
V=(16 q)^(hp-(c-1)/24) z^((c-1)/24-2hL) (1-z)^((c-1)/24-hH-hL) EllipticTheta[3,0,q]^((c-1)/2-8(hH+hL)) (Table[q^i,{i,0,maxOrder,2}].Take[coeVec,1+Floor[maxOrder/2]])/.q->EllipticNomeQ[z];
Return[V];
];
VVofT[coeVec_,c_,hL_,hH_,hp_,r_,tL_,maxOrder_]:=Module[{z,q},
q=VqVal[r,tL];
z=1-r*E^(-I tL);
(16 q)^(hp-(c-1)/24) z^((c-1)/24-2hL) (r)^((c-1)/24-hH-hL) E^(-I tL ((c-1)/24-hH-hL)) EllipticTheta[3,0,q]^((c-1)/2-8(hH+hL))*(Table[q^i,{i,0,maxOrder,2}].Take[coeVec,1+Floor[maxOrder/2]])
];
VSemiClassical[c_,hL_, hH_,r_,tL_]:=Module[{\[Alpha]},((\[Alpha]^(2 hL) r^((\[Alpha]-1)hL) E^(-I tL(\[Alpha]-1)hL))/(1-r^\[Alpha] E^(-I tL \[Alpha]))^(2hL))/.\[Alpha]->Sqrt[1-(24hH)/c]
];
VSemiOfZ[c_,hL_,hH_,z_]:=Module[{\[Alpha]},Exp[((\[Alpha]-1)Log[1-z]-2Log[(1-(1-z)^\[Alpha])/\[Alpha]])hL]/.\[Alpha]->Sqrt[1-24 hH/c]];
VDegenBlock12[c_,hL_,hh_,r_,tL_]:=Module[{a1,b1,c1,z,bsq},
bsq=VGetBsq[c];
1/(1-r*Exp[-I tL])^(2hL) r^b1 Exp[-I b1 tL/2]((Gamma[a1+b1-c1] Gamma[c1])/(Gamma[a1] Gamma[b1]) r^(-a1-b1+c1) Exp[-I (-tL a1-tL b1+tL c1)] Hypergeometric2F1[-a1+c1,-b1+c1,1-a1-b1+c1,r E^(-I tL)] +(Gamma[-a1-b1+c1] Gamma[c1])/(Gamma[c1-a1] Gamma[c1-b1]) Hypergeometric2F1[a1,b1,a1+b1-c1+1,r E^(-I tL)] )/.{a1->1+1/bsq,b1->(1+bsq+Sqrt[1+bsq^2+bsq *(2-4 hh)])/bsq,c1->2+2/bsq}/.z->1-r E^(-I tL)
];
VDegenBlock21[c_,hL_,hh_,r_,tL_]:=Module[{a1,b1,c1,z,bsq},
bsq=VGetBsq[c];
1/(1-r Exp[-I tL])^(2hL) r^b1 Exp[-I b1 tL/2]((Gamma[a1+b1-c1] Gamma[c1])/(Gamma[a1] Gamma[b1]) r^(-a1-b1+c1) Exp[-I (-tL a1-tL b1+tL c1)] Hypergeometric2F1[-a1+c1,-b1+c1,1-a1-b1+c1,r E^(-I tL)] +(Gamma[-a1-b1+c1] Gamma[c1])/(Gamma[c1-a1] Gamma[c1-b1]) Hypergeometric2F1[a1,b1,a1+b1-c1+1,r E^(-I tL)] )/.{a1->1+bsq,b1->(1+1/bsq+Sqrt[1+bsq^(-2)+1/bsq *(2-4 hh)])*bsq,c1->2+2*bsq}/.z->1-r E^(-I tL)
];

VRun::paramError = "Enter 5 parameters, either separately or as a vector.";
VRun::noVWSTP = "VWSTP not found. It must either be installed in /usr/local/bin or be in the same directory as Virasoro.m and must be marked as executable.";
VRun[c_,hl_,hh_,hp_,maxOrder_] := Module[{link,params,results},
link = Install["/usr/local/libexec/vwstp"];
If[link==$Failed,link = Install[NotebookDirectory[]<>"vwstp"]];
If[link==$Failed,Failure["C++NotFound",<|"MessageTemplate":>VRun::noVWSTP|>]];
params = ToString/@N[Rationalize[{c,hl,hh,hp,maxOrder}],768];
Do[If[StringContainsQ["I"]@params[[i]],
params[[i]] = StringInsert[params[[i]],"(",1];
params[[i]] = StringInsert[params[[i]],")",-1];
params[[i]] = StringReplace[params[[i]], {" +" -> "", " -" -> "", " I" -> ""}];
],{i,1,Length@params}];
results = Global`VPass[params[[1]],params[[2]],params[[3]],params[[4]],params[[5]]];
Uninstall[link];
Return[results];
];

VRunFromFile::notFound = "The argument given was not a vector of parameters or valid filename.";
VRunFromFile[filename_]:=Module[{link,results},
If[FindFile[NotebookDirectory[]<>filename] == $Failed,
Failure["FileNotFound", <|"MessageTemplate":>VRunFromFile::notFound|>]];
link = Install["/usr/local/libexec/vwstp"];
If[link==$Failed,link = Install[NotebookDirectory[]<>"vwstp"]];
If[link==$Failed,Failure["C++NotFound",<|"MessageTemplate":>VRun::noVWSTP|>]];
results = Global`VPassFilename[NotebookDirectory[]<>filename];
Uninstall[link];
Return[results];
];

VRun[paramVec_]:=Module[{stringParam,results},
If[VectorQ[paramVec], stringParam=ToString/@paramVec, stringParam=StringReplace[ToString@paramVec," "->""]];
Switch[Length@stringParam
,0,results=VRunFromFile[stringParam];
,1,results=VRunFromFile[stringParam[[1]]];
,5,results=VRun[stringParam[[1]],stringParam[[2]],stringParam[[3]],stringParam[[4]],stringParam[[5]]];
,_, Failure["InvalidParameters", <|"MessageTemplate":>VRun::paramError|>]];
Return[results];
];

VLengthCheck[filename_]:=Module[{resultFile,entries, null},
resultFile=OpenRead[filename,BinaryFormat->True];
entries =0;
null[_String]:=Null;
entries=Length@ReadList[filename,null@String,NullRecords->True];
Close[filename];
Return[entries];
];

VRead[filename_]:=Module[{resultFile,entries,null,results},
entries=VLengthCheck[filename];
results=ConstantArray[0,entries];
resultFile=OpenRead[filename,BinaryFormat->True];
Do[
results[[2i-1]]=ToExpression@StringReplace[ReadLine[resultFile],"e"->"*10^"];
results[[2i]]=ToExpression@StringReplace[ReadLine[resultFile],"e"->"*10^"];
,{i,1,entries/2}];
Close[filename];
Return[results];
];

VWrite[results_, rawFilename_]:=Module[{filename, resultFile},
If[StringCount[rawFilename, "/"] == 0, filename = NotebookDirectory[]<>ToString@rawFilename, filename = ToString@rawFilename];
resultFile=OpenWrite[filename,PageWidth->Infinity];
Do[
WriteString[resultFile,NumberForm[results[[i]], ExponentFunction->(Null&)]];
WriteString[resultFile,"\n"];
,{i,1,Length@results}];
Close[resultFile];
Return[];
];

VMakePlotLabel[results_,runNumber_]:=Module[{c,hl,hh,h,label},
c=results[[2runNumber-1]][[1]];
hl=results[[2runNumber-1]][[2]];
hh=results[[2runNumber-1]][[3]];
h=results[[2runNumber-1]][[4]];
label=Row[{
	Style["c",Black,FontFamily->"CMU Classical Serif"],
	Style["="<>StringTake[ToString@c,Min[5,StringLength[ToString@c]]]<>",    ",Black,FontFamily->"CMU Serif"],
	Style["\!\(\*SubscriptBox[\(h\), \(L\)]\)",Black,FontFamily->"CMU Classical Serif"],
	Style["="<>StringTake[ToString@hl,Min[5,StringLength[ToString@hl]]]<>",    ",Black,FontFamily->"CMU Serif"],
	Style["\!\(\*SubscriptBox[\(h\), \(H\)]\)",Black,FontFamily->"CMU Classical Serif"],
	Style["="<>StringTake[ToString@hh,Min[5,StringLength[ToString@hh]]]<>",    ",Black,FontFamily->"CMU Serif"],
	Style["h",Black,FontFamily->"CMU Classical Serif"],
	Style["="<>StringTake[ToString@h,Min[5,StringLength[ToString@h]]],Black,FontFamily->"CMU Serif"]}];
(*label="c="<>StringTake[ToString@c,Min[5,StringLength[ToString@c]]]<>",    \!\(\*SubscriptBox[\(h\), \(L\)]\)="<>StringTake[ToString@hl,Min[5,StringLength[ToString@hl]]]<>",    \!\(\*SubscriptBox[\(h\), \(H\)]\)="<>StringTake[ToString@hh,Min[5,StringLength[ToString@hh]]]<>",    h="<>StringTake[ToString@h,Min[5,StringLength[ToString@h]]];*)
Return[label];
];

Options[VPlotCoeffs]={StartingRun->1, EndingRun->0, RunStep->1};
VPlotCoeffs[results_,OptionsPattern[]]:=Module[{c,hl,hh,hp},
Do[If[Length@results[[2*i]]<10,Continue[]];
c=results[[2i-1]][[1]];
hl=results[[2i-1]][[2]];
hh=results[[2i-1]][[3]];
hp=results[[2i-1]][[4]];
Print[ListLogLogPlot[{results[[2*i]],-results[[2*i]]},PlotLabel->VMakePlotLabel[results,i],PlotMarkers->"\[FilledSmallCircle]",PlotStyle->{Lighter@Blue,Lighter@Red},PlotLegends->{"Blue > 0","Red < 0"},DataRange->{0,2*Length@results[[2*i]]}]];
(*Print[ListPlot[LogFluct[results[[2*i]]],PlotLabel\[Rule]"Fluctuations about smoothed average log", PlotMarkers\[Rule]"\[FilledSmallCircle]",ColorFunction\[Rule]Coloring,ColorFunctionScaling\[Rule]False,DataRange\[Rule]{0,2*Length@results[[2*i]]}]];*)
,{i,OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,OptionValue[EndingRun],Length@results/2],OptionValue[RunStep]}];
];

Options[VPlot]={StartingRun->1, EndingRun->0, RunStep->1, r->0.3, PlotScale->"SemiLog", StartTime->0.1, EndTime->30, Compare->{}, PointsPerTL->1};
VPlot[results_,OptionsPattern[]]:=Module[{c,hl,hh,hp,startTime,endTime, compareVec, plotVector, plotLegends,plotType},
startTime=OptionValue[StartTime];
endTime=OptionValue[EndTime];
If[VectorQ[OptionValue[Compare]],compareVec = OptionValue[Compare], compareVec = {OptionValue[Compare]}];
Do[If[Length@results[[2*i]]<10,Continue[]];
c=results[[2i-1]][[1]];
hl=results[[2i-1]][[2]];
hh=results[[2i-1]][[3]];
hp=results[[2i-1]][[4]];
plotVector := {Abs@VVofT[results[[2*i]],c,hl,hh,hp,OptionValue[r],tL,2*Length@results[[2*i]]-2]};
plotLegends := {"Computed"};
If[MemberQ[compareVec, "Semi"],
plotVector=Append[Abs@VSemiClassical[c,hl,hh,OptionValue[r],tL]]@plotVector;
plotLegends=Append["Semiclassical"]@plotLegends;
];
If[MemberQ[compareVec, "12"],
plotVector=Append[{Abs@VDegenBlock12[c,hl,hh,OptionValue[r],tL]}]@plotVector;
plotLegends=Append["Exact Degenerate \!\(\*SubscriptBox[\(h\), \(12\)]\)"]@plotLegends;
];
If[MemberQ[compareVec, "21"],
plotVector=Append[{Abs@VDegenBlock21[c,hl,hh,OptionValue[r],tL]}]@plotVector;
plotLegends=Append["Exact Degenerate \!\(\*SubscriptBox[\(h\), \(21\)]\)"]@plotLegends;
];
(*Print[plotVector/.tL\[Rule]1//N];
Print[Abs@VSemiClassical[c,hl,hh,r,1]];*)
If[StringMatchQ[OptionValue[PlotScale],"Linear"],plotType=Plot];
If[StringMatchQ[OptionValue[PlotScale],"SemiLog"]||StringMatchQ[OptionValue[PlotScale],"LogLinear"],plotType=LogPlot];
If[StringMatchQ[OptionValue[PlotScale],"LogLog"],plotType=LogLogPlot];
Print[plotType[Evaluate[plotVector],{tL,startTime,endTime},PlotRange->All,PlotLegends->plotLegends,PlotLabel->VMakePlotLabel[results,i],AxesLabel->{"\!\(\*SubscriptBox[\(t\), \(L\)]\)","V(\!\(\*SubscriptBox[\(t\), \(L\)]\))"},PlotPoints->Max[OptionValue[PointsPerTL]*Ceiling[endTime-startTime],50]]];;
,{i,OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,OptionValue[EndingRun],Length@results/2],OptionValue[RunStep]}];
];

Options[VConvByOrder]={r->0.3, StartingRun->1, RunStep->1, EndingRun->0};
VConvByOrder[results_,tL_,OptionsPattern[]]:=Module[{plotLabel,q},
Do[
Print[DiscretePlot[Table[q^k,{k,0,2*Floor[i/2],2}].Take[results[[entry]],Floor[i/2]+1]/.q->VqVal[OptionValue[r],tL]//Abs,{i,Length[results[[entry]]]/5,2*Length[results[[entry]]],2},PlotRange->Full,AxesLabel->{"Max Order","H(r="<>ToString@OptionValue[r]<>",tL="<>ToString@tL<>")"},Filling->None,PlotMarkers->"\[FilledSmallCircle]",PlotLabel->VMakePlotLabel[results,entry/2]]];
,{entry,2*OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,2*OptionValue[EndingRun],Length@results],2*OptionValue[RunStep]}];
];

Options[VConvByTL]={StartingRun->1, RunStep->1, EndingRun->0,StartTime->0.1,EndTime->50,r->0.3};
VConvByTL[results_,OptionsPattern[]]:=Module[{plotLabel,q},
Do[
Print[Plot[(Table[q^k,{k,0,2*Length@results[[entry]]-2,2}].results[[entry]])/(Table[q^k,{k,0,2*Max[Length@results[[entry]]-10,1]-2,2}].Take[results[[entry]],Max[Length@results[[entry]]-10,1]])/.q->VqVal[OptionValue[r],tL]//Abs,{tL,OptionValue[StartTime],OptionValue[EndTime]},PlotRange->Full,AxesLabel->{"tL","H(r="<>ToString@OptionValue[r]<>")"},PlotLabel->VMakePlotLabel[results,entry/2]]];
,{entry,2*OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,2*OptionValue[EndingRun],Length@results],2*OptionValue[RunStep]}];
];

Options[VFindEndTimes]={StartingRun->1, RunStep->1, EndingRun->0,StartTime->0.1,EndTime->50,r->0.3,Bins->1000};
VFindEndTimes[results_,OptionsPattern[]]:=Module[{tL,q,ends},
ends={};
Do[
	Do[
		tL=i*(OptionValue[EndTime]-OptionValue[StartTime])/OptionValue[Bins];
		If[Abs[(Table[q^k,{k,0,2*Length@results[[entry]]-2,2}].results[[entry]])/(Table[q^k,{k,0,2*Max[Length@results[[entry]]-10,1]-2,2}].Take[results[[entry]],Max[Length@results[[entry]]-10,1]])/.q->VqVal[OptionValue[r],tL]]>=1.05,
			AppendTo[ends,tL];
			Break[];
		];
		If[i==OptionValue[Bins],AppendTo[ends,OptionValue[EndTime]]];
	,{i,0,OptionValue[Bins]}];
,{entry,2*OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,2*OptionValue[EndingRun],Length@results],2*OptionValue[RunStep]}];
Return[ends];
];

Options[VConvByQ]={StartingRun->1, RunStep->1, EndingRun->0,r->0.3};
VConvByQ[results_,OptionsPattern[]]:=Module[{plotLabel,q},
Do[
Print[ContourPlot[(Table[q^k,{k,0,2*Length@results[[entry]]-2,2}].results[[entry]])/(Table[q^k,{k,0,2*Max[Length@results[[entry]]-10,1]-2,2}].Take[results[[entry]],Max[Length@results[[entry]]-10,1]])/.q->(x+I y)//Abs,{x,y}\[Element]Disk[],PlotLabel->VMakePlotLabel[results,entry/2]]];
,{entry,2*OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,2*OptionValue[EndingRun],Length@results],2*OptionValue[RunStep]}];
];

Options[VZMap]={StartingRun->1,RunStep->1,EndingRun->0,Compare->"",x->{0,10},y->{-5,5}};
VZMap[results_,OptionsPattern[]]:=Module[{compareVec,plotFunc,plot,xBounds,yBounds},
If[(Length@OptionValue[x])==2,xBounds=OptionValue[x],xBounds={0,10}];
If[(Length@OptionValue[y])==2,yBounds=OptionValue[y],yBounds={-5,5}];
If[VectorQ[OptionValue[Compare]],compareVec = OptionValue[Compare], compareVec = {OptionValue[Compare]}];
If[MemberQ[compareVec, "Semi"],
plotFunc[x_,y_,entry_]:=Log@Abs@(VVofZ[x+I*y,results[[entry]],results[[entry-1]][[1]],results[[entry-1]][[2]],results[[entry-1]][[3]],results[[entry-1]][[4]],results[[entry-1]][[5]]]/VSemiOfZ[results[[entry-1]][[1]],results[[entry-1]][[2]],results[[entry-1]][[3]],x+I*y]),
plotFunc[x_,y_,entry_]:=Log@Abs@VVofZ[x+I*y,results[[entry]],results[[entry-1]][[1]],results[[entry-1]][[2]],results[[entry-1]][[3]],results[[entry-1]][[4]],results[[entry-1]][[5]]]
];
Do[
plot=ContourPlot[plotFunc[x,y,entry],{x,0,10},{y,-5,5},PlotLabel->VMakePlotLabel[results,entry/2],PlotLegends->BarLegend[Automatic,LegendMarkerSize->180,LegendFunction->"Frame",LegendMargins->5,LegendLabel->"Log@Abs@V(z)"]];
Print[plot];
,{entry,2*OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,2*OptionValue[EndingRun],Length@results],2*OptionValue[RunStep]}];
];
End[]

Options[VDepTime]={r->0.3,StartingRun->1,RunStep->1,EndingRun->0,Ratio->1.1};
VDepTime[results_,OptionsPattern[]]:=Module[{c,hl,hh,hp,tL},
Print[{"\!\(\*FractionBox[\(c\), SubscriptBox[\(h\), \(L\)]]\)","\!\(\*SubscriptBox[\(t\), \(d\)]\)"}];
Do[
c=results[[2i-1]][[1]];
hl=results[[2i-1]][[2]];
hh=results[[2i-1]][[3]];
hp=results[[2i-1]][[4]];
tL=1;
While[Abs[VVofT[results[[2*i]],c,hl,hh,hp,OptionValue[r],tL,2*Length@results[[2*i]]-2]/VSemiClassical[c,hl,hh,OptionValue[r],tL]]<=OptionValue[Ratio],tL+=1];
tL-=1;
While[Abs[VVofT[results[[2*i]],c,hl,hh,hp,OptionValue[r],tL,2*Length@results[[2*i]]-2]/VSemiClassical[c,hl,hh,OptionValue[r],tL]]<=OptionValue[Ratio],tL+=0.1];
tL-=0.1;
While[Abs[VVofT[results[[2*i]],c,hl,hh,hp,OptionValue[r],tL,2*Length@results[[2*i]]-2]/VSemiClassical[c,hl,hh,OptionValue[r],tL]]<=OptionValue[Ratio],tL+=0.01];
tL-=0.005;
Print["-----"];
Print[{N[c,4],N[hl,4],N[hh,4],N[hp,4]}];
Print[{N[c/hl,5],N[tL,5]}];
,{i,OptionValue[StartingRun],If[OptionValue[EndingRun]!=0,OptionValue[EndingRun],Length[results]/2]}];
];

EndPackage[]



