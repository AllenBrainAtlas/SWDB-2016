def cumsum(lower_bound,upper_bound,upper_inclusive=True):
    '''
    THIS FUNCTION WAS DEFINED EXTERNALLY
    returns sum of all integers between lower_bound and upper_bound
    
    Includes upper_bound in sum by default. Exclude upper bound by setting:
    
        upper_inclusive = False        
    '''
    result = 0
    for number in range(lower_bound,upper_bound+int(upper_inclusive)):
        result += number

    return result

def print_something2(input_string):
    print input_string