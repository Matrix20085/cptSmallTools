#Python 3.9

import os
import argparse


parser = argparse.ArgumentParser()
parser.add_argument('-p','--path',action='store',dest='basePath',required=True, help='Path to share. Ex: "Z:","/home/cpt/share"')
parser.add_argument('-o','--operators',action='store',dest='operators',help='List of names comma seperated')
args = parser.parse_args()


if not os.path.isdir(args.basePath):
	sys.exit("Provided path is not correct: " + str(args.basePath))

topPathList = ['data','working','documentation']
internalExternal = ['internal','external']
workingPathList = args.operators.replace(' ', '').split(',')
dataPathList = ['database','networkMapping','vulnerabilityScanning','webApp','phishing','wireless','penetrationTesting']
networkPathList = ['eyewitness','aquatone','nmap']

os.mkdir(os.path.join(args.basePath,"data"))
os.mkdir(os.path.join(args.basePath,"data/penetrationTesting"))
os.mkdir(os.path.join(args.basePath,"data/penetrationTesting/internal"))
os.mkdir(os.path.join(args.basePath,"data/penetrationTesting/external"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/internal"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/internal/eyewitness"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/internal/aquatone"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/internal/nmap"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/external"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/external/eyewitness"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/external/aquaton"))
os.mkdir(os.path.join(args.basePath,"data/networkMapping/external/nmap"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning/internal"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning/internal/nikto"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning/internal/nessus"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning/external"))
os.mkdir(os.path.join(args.basePath,"data/vulnerabilityScanning/external/nessus"))
os.mkdir(os.path.join(args.basePath,"data/webApp"))
os.mkdir(os.path.join(args.basePath,"data/webApp/external"))
os.mkdir(os.path.join(args.basePath,"data/webApp/external/nikto"))
os.mkdir(os.path.join(args.basePath,"data/webApp/external/burpSuite"))
os.mkdir(os.path.join(args.basePath,"data/webApp/internal"))
os.mkdir(os.path.join(args.basePath,"data/webApp/internal/nikto"))
os.mkdir(os.path.join(args.basePath,"data/webApp/internal/burpSuite"))
os.mkdir(os.path.join(args.basePath,"data/phishing"))
os.mkdir(os.path.join(args.basePath,"documentation"))
os.mkdir(os.path.join(args.basePath,"working"))

if args.operators:
	for operator in workingPathList:
		os.mkdir(os.path.join(args.basePath,"working",operator))
