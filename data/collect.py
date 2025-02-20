import re

def process_data(filename):
    results = {}
    dafl_pattern = re.compile(r'pacfix-dafl-(\d+)\.log')
    reset_pattern = re.compile(r'pacfix-cludafl-reset-(\d+)\.log')

    with open(filename, 'r') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) != 4:
                continue  # 유효하지 않은 행 스킵
            subject, test_name, _, sample_info = parts
            
            if subject not in results:
                results[subject] = {}

            dafl_match = dafl_pattern.match(test_name)
            reset_match = reset_pattern.match(test_name)

            if dafl_match:
                dafl_num = dafl_match.group(1)
                if dafl_num == "10":
                    key = f'dafl_{dafl_num}'
                    results[subject][key] = sample_info
                elif dafl_num.isdigit() and 1<=int(dafl_num)<=9:
                    key = f'dafl_{dafl_num}'
                    results[subject][key] = sample_info
            elif reset_match:
                reset_num = reset_match.group(1)
                key = f'cludafl_reset_{reset_num}'
                results[subject][key] = sample_info


    return results


if __name__ == "__main__":
    filename = 'dafl-cludafl-10.csv'

    processed_data = process_data(filename)

    ordered_keys = [f'dafl_{i}' for i in range(1, 11)] + \
                    [f'cludafl_reset_{i}' for i in range(0, 11)]
                    
    # 헤더 출력
    header = ["subject"] + ordered_keys
    print("\t".join(header))

    # 결과 출력
    for subject, data in processed_data.items():
        output_line = [subject]
        for key in ordered_keys:
          output_line.append(data.get(key, 'N/A'))
        print("\t".join(output_line))