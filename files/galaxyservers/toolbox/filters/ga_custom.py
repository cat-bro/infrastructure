# try:
#     with open('/srv/galaxy/server/config/deprecated_tools.txt') as deprecated_list:
#         deprecated_tools = [line.strip() for line in deprecated_list.readlines()]
# except Exception:
#     deprecated_tools = []
# 

hidden_tool_list = ['toolshed.g2.bx.psu.edu/repos/iuc/snpeff/snpEff/4.3r.1']


def hide_tools(context, tool):
    """
    hide tools specified in 'deprecated_tools.txt' from tool panel
    """
    # print(tool, content)
    # print(dir(tool))
    print('*** this is the filter')
    print(tool)
    if hasattr(tool, 'id') and tool.id in hidden_tool_list:
        return False
    return True
