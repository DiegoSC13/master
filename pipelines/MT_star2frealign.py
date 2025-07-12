#!/usr/bin/env python
import os, sys, math, re

def main():
    options = parse_command_line()
    input_star = options.input_star
    apix = options.apix
    make_frealign_lst(input_star, apix, options)


def make_frealign_lst(input_star, apix, options):
    #star = StarFile(input_star)
    labelDict, header, mainlines = star_read(input_star)

    data = []
    FORMAT = "%7d%8.2f%8.2f%8.2f%10.2f%10.2f%8d%6d%9.1f%9.1f%8.2f%8.2f%10d%11.4f%8.2f%8.2f\n"

    film = 1
    # ele0 = mainlines[0].split()
    # segment = (ele0[labelDict["_rlnHelicalTubeID"]], ele0[labelDict["_rlnImageName"]].split("@")[1].split("/")[-1])

    for i in range(0, len(mainlines)):
        ele = mainlines[i].split()
        element = []
        element.append('%s' % (i + 1))
        psi = round(float(ele[labelDict['_rlnAnglePsi']]), 2)
        element.append('%.2f' % psi)
        theta = round(float(ele[labelDict['_rlnAngleTilt']]), 2)
        element.append('%.2f' % theta)
        phi = round(float(ele[labelDict['_rlnAngleRot']]), 2)
        element.append('%.2f' % phi)
        shx, shy = -round(float(ele[labelDict['_rlnOriginX']]) * apix, 2), -round(float(ele[labelDict['_rlnOriginY']]) * apix, 2)
        element.append('%.2f' % shx)
        element.append('%.2f' % shy)
        mag = int(float(ele[labelDict['_rlnMagnification']]))
        element.append(str(mag))

        # tmp = (ele[labelDict["_rlnHelicalTubeID"]], ele[labelDict["_rlnImageName"]].split("@")[1].split("/")[-1])
        # if segment != tmp:
        #     segment = tmp
        #     film += 1

        element.append(str(film))
        df1, df2 = round(float(ele[labelDict['_rlnDefocusU']]), 1), round(float(ele[labelDict['_rlnDefocusV']]), 1)
        element.append('%.1f' % df1)
        element.append('%.1f' % df2)
        angast = round(float(ele[labelDict['_rlnDefocusAngle']]), 2)
        element.append('%.2f' % angast)
        # extra value for "occ logp sigma score change"
        element.append('100.00'), element.append('-500'), element.append('1.0000'), element.append(
            '20.00'), element.append('0.00')
        data.append(FORMAT%(int(element[0]), float(element[1]), float(element[2]), float(element[3]), float(element[4]), float(element[5]), int(element[6]), int(element[7]), float(element[8]), float(element[9]), float(element[10]), float(element[11]), int(element[12]), float(element[13]), float(element[14]), float(element[15])))

    outPar = options.outPar
    f = open(outPar, 'w')
    for i in range(0, len(data)):
        f.write(data[i])
    f.close()

    '''cmd = "parformat_fang.com tmp.txt %s" % (outPar)
    os.system(cmd)'''

def star_read(starfile):
    f = open(starfile, 'r')
    lines = f.readlines()
    labeldict = {}
    for i in range(0, len(lines)):
        if re.search('_rln', lines[i]) and re.search('\\#', lines[i]):
            labeldict[lines[i].split()[0]] = int(lines[i].split()[1].strip('#').strip('\n')) - 1
    # get header
    header = []
    for i in range(0, len(lines)):
        if '/' not in lines[i] and '@' not in lines[i]:
            header.append(lines[i])
        else:
            break
    # get mainlines
    mainlines = []
    for i in range(0, len(lines)):
        if '/' in lines[i] or '@' in lines[i]:
            mainlines.append(lines[i])
    f.close()
    return (labeldict, header, mainlines)

def parse_command_line():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_star', metavar="<input>", type=str, help='input star file')
    parser.add_argument('--apix', metavar="<A/pix>", type=float, help='pixel size of the images')
    parser.add_argument('--outPar', metavar="<fn>", type=str, help='output par file')

    if len(sys.argv) < 4:
        parser.print_help()
        sys.exit(-1)
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    main()
