import os

def update_categories(input_file, output_file):
    category_mapping = {
        5: 6,
        6: 7,
        11: 12
    }
    
    header_lines = []
    data_lines = []
    current_comment = ""
    
    with open(input_file, 'r') as file:
        for line in file:
            line = line.strip()
            
            if not line:
                continue
                
            if line.startswith('//'):
                header_lines.append(line)
                continue
                
            if line.startswith('#'):
                current_comment = line
                continue
                
            parts = line.split()
            if len(parts) >= 5:
                map_name = parts[0]
                category = int(parts[1])
                time = float(parts[2])
                medal = int(parts[3])
                reward = int(parts[4])
                remaining_comment = ' '.join(parts[5:]) if len(parts) > 5 else '# Unknown'
                
                if category in category_mapping:
                    category = category_mapping[category]
                
                new_line = f"{map_name} {category} {time:.3f} {medal} {reward} {remaining_comment}"
                data_lines.append((current_comment, new_line))
    
    with open(output_file, 'w') as file:
        for line in header_lines:
            file.write(line + '\n')
        file.write('\n')
        
        previous_comment = None
        for comment, line in data_lines:
            if comment != previous_comment:
                file.write('\n' + comment + '\n\n')
                previous_comment = comment
            file.write(line + '\n')

directory = r"FILE_PATH_HERE" # File path
input_file = os.path.join(directory, "medals.ini")
output_file = os.path.join(directory, "medals_organizado.ini")

update_categories(input_file, output_file)
print(f"Updated file saved as '{output_file}'")