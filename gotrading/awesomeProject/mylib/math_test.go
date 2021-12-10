package mylib

import "testing"

func TestAverage(t *testing.T) {
	type args struct {
		s []int
	}
	tests := []struct {
		name string
		args args
		want int
	}{
		// TODO: Add test cases.
		{
			name: "case1",
			args: args{[]int{1, 2, 3, 4, 5}},
			want: 3,
		},
		{
			name: "case2",
			args: args{[]int{}},
			want: 0,
		},
		{
			name: "case3",
			args: args{[]int{1}},
			want: 0,
		},
		{
			name: "case4",
			args: args{[]int{1.0, 2.0}},
			want: 0,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Average(tt.args.s); got != tt.want {
				t.Errorf("Average() = %v, want %v", got, tt.want)
			}
		})
	}
}
