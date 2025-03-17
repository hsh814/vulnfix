import json
import os

PATH='/home/yuntong/vulnfix/data'

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
    'libtiff/cve_2016_9532',
    'libtiff/cve_2016_10094',
    'libtiff/cve_2017_7599',
    'libtiff/cve_2017_7600',
    'libtiff/cve_2017_7601',
    'libxml2/cve_2012_5134',
    'libxml2/cve_2016_1838',
    'libxml2/cve_2016_1839',
    'libxml2/cve_2017_5969',
    'zziplib/cve_2017_5974',
    'zziplib/cve_2017_5975',
    'zziplib/cve_2017_5976',
]

result=dict()
ranking=dict()
for d in dirs:
    if not os.path.exists(os.path.join(PATH, d,'cludafl_out')) or not os.path.exists(os.path.join(PATH, d,'cludafl_out','cludafl-seed-clustering')):
        # Not run in this server
        continue
    print(f'Processing {d}')
    result[d]=dict()
    result_for_ranking=dict()
    cur_path=os.path.join(PATH, d,'cludafl_out','cludafl-seed-clustering')
    for res_dir in os.listdir(cur_path):
        if res_dir=='memory': continue
        cur_seed_dir=os.path.join(cur_path,res_dir,'queue')
        cur_seed=None
        for cs in os.listdir(cur_seed_dir):
            if cs.startswith('id:000000'):
                cur_seed=cs.split(':')[2]
                break
        if cur_seed is None:
            raise ValueError(f'Cannot find initial seed name for {d}/{res_dir}')
        target_reached_inputs=len(os.listdir(os.path.join(cur_path,res_dir,'memory','input')))
        target_reached_inputs_crashed=len(os.listdir(os.path.join(cur_path,res_dir,'memory','neg')))
        target_reached_inputs_uncrashed=target_reached_inputs-target_reached_inputs_crashed
        result[d][cur_seed]={
            'target_reached': target_reached_inputs,
            'target_reached_crashed': target_reached_inputs_crashed,
            'target_reached_uncrashed': target_reached_inputs_uncrashed,
        }
        if target_reached_inputs>0:
            result_for_ranking[cur_seed]=target_reached_inputs
    
    sorted_rank=sorted(result_for_ranking.items(),key=lambda x:x[1],reverse=True)
    ranking[d]=[x[0] for x in sorted_rank]

with open('seed_result.json','w') as f:
    f.write(json.dumps(result,indent=4))

with open('seed_ranking.json','w') as f:
    f.write(json.dumps(ranking,indent=4))