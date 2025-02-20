import os
import sys
from typing import List, Dict
import sbsv
import matplotlib.pyplot as plt
import numpy as np

def read_log(log_file: str) -> sbsv.parser:
    parser = sbsv.parser()
    parser.add_schema("[dry-run] [entry: int] [file: str] [hash: int] [dfg: int] [res: int] [prox: int] [pre: int]")
    parser.add_schema("[seed] [seed: int] [new-entry: int] [prox: int]")
    parser.add_schema("[PacFuzz] [save_valuation] [pos] [seed: int] [entry: int] [id: int] [hash: int] [time: int] [file: str]")
    parser.add_schema("[PacFuzz] [save_valuation] [neg] [seed: int] [entry: int] [id: int] [hash: int] [time: int] [file: str]")
    with open(log_file, 'r') as f:
        parser.load(f)
        return parser

class EntryNode:
    def __init__(self, entry: int, parent = None):
        self.entry = entry
        self.parent = parent
        self.children:List[EntryNode] = []
        self.count=0

    def find_root(self):
        if self.parent is None:
            return self
        return self.parent.find_root()
    
    def increase_count(self,n=1):
        self.count+=n
        if self.parent is not None:
            self.parent.increase_count(n)

    def get_children_count(self):
        count=1 # Include self
        for child in self.children:
            count+=child.get_children_count()
        return count

if __name__ == "__main__":
    if len(sys.argv) < 3:
        dirs=['binutils/cve_2017_6965',
            #   'binutils/cve_2017_15025',
              'coreutils/gnubug_19784',
              'coreutils/gnubug_25003',
              'coreutils/gnubug_25023',
              'coreutils/gnubug_26545',
              'jasper/cve_2016_8691',
              'jasper/cve_2016_9557',
              'libjpeg/cve_2012_2806',
              'libjpeg/cve_2017_15232',
              'libming/cve_2016_9264',
              'libtiff/bugzilla_2633',
              'libtiff/cve_2016_5321',
            #   'libtiff/cve_2016_9532',
              'libtiff/cve_2016_10094',
              'libtiff/cve_2017_7599',
              'libtiff/cve_2017_7600',
              'libtiff/cve_2017_7601',
              'libxml2/cve_2012_5134',
              'libxml2/cve_2016_1838',
              'libxml2/cve_2016_1839',
              'libxml2/cve_2017_5969',
              'zziplib/cve_2017_5974',
            #   'zziplib/cve_2017_5976',
              ]
        postfix=sys.argv[1]
    else:
        dirs=sys.argv[1]
        postfix=sys.argv[2]

    for dir in dirs:
        print(dir,end='')
        base = os.path.basename(dir)
        proj = os.path.basename(os.path.dirname(dir))

        log_path = os.path.join(dir, "cludafl_out")
        x=[]
        total_y=[]
        for i in range(4,11):
            parser = read_log(os.path.join(log_path, f"out-{postfix}-{i}", "unique_dafl.log"))
            cludafl_result = parser.get_result()
            node_list:Dict[int,List[EntryNode]] = dict()
            root_seeds:List[EntryNode] = []
            for entry in cludafl_result["dry-run"]:
                entry_node=EntryNode(entry["entry"])
                root_seeds.append(entry_node)
                node_list[entry['entry']]=[entry_node]
            
            for val in cludafl_result["seed"]:
                entry = val["new-entry"]
                seed = val["seed"]
                
                for node in node_list[seed]:
                    new_node=EntryNode(entry,node)
                    node.children.append(new_node)
                    if entry not in node_list:
                        node_list[entry]=[]
                    node_list[entry].append(new_node)
                
            inter_result = dict()
            for val in parser.get_result_in_order(["[PacFuzz] [save_valuation] [pos]", "[PacFuzz] [save_valuation] [neg]"]):
                seed = val["seed"]
                inter_result[seed] = inter_result.get(seed, 0) + 1
                if seed==-1: continue  # This is initial seed
                for node in node_list[seed]:
                    node.increase_count()

            # print('seed\tcount')
            y=[]
            for j,root in enumerate(root_seeds):
                # print(f'{root.entry}\t{root.get_children_count()}')
                if i==4:
                    x.append(root.entry)
                    total_y.append(root.count)
                else:
                    total_y[j]+=root.count
                y.append(root.count)

            plt.clf()
            plt.bar(x,y)
            plt.xlabel('Root Seeds')
            plt.ylabel('# of Usage')
            plt.grid()
            plt.savefig(f"/home/yuntong/vulnfix/fig-seeds/{proj}-{base}-seeds-{postfix}-{i}-bar.jpg")

            with open(f"/home/yuntong/vulnfix/fig-seeds/{proj}-{base}-seeds-{postfix}-{i}.csv",'w') as f:
                print('seed,count',file=f)
                for _x,_y in zip(x,y):
                    print(f'{_x},{_y}',file=f)

                print(f'standard deviation,{np.std(y)}',file=f)

        plt.clf()
        plt.bar(x,total_y)
        plt.xlabel('Root Seeds')
        plt.ylabel('# of Usage')
        plt.grid()
        plt.savefig(f"/home/yuntong/vulnfix/fig-seeds/total-seed-{proj}-{base}-seeds-{postfix}-bar.jpg")

        # with open(f"/home/yuntong/vulnfix/fig-seeds/total-seed-{proj}-{base}-seeds-{postfix}.csv",'w') as f:
        #     print('seed,count',file=f)
        #     for _x,_y in zip(x,total_y):
        #         print(f'{_x},{_y}',file=f)

        #     print(f'standard deviation,{np.std(total_y)}',file=f)
        print(f': standard deviation: {np.std(total_y)}')