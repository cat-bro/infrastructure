# This file is managed by ansible.  Do not edit it directly
# To add extra local functions, make a PR with usegalaxy-au/infrastructure
# or create a file ~/.config/gxadmin-local-extra.sh

GXADMIN_LOCAL_EXTRA=${BASH_SOURCE%/*}/gxadmin-local-extra.sh
[ -f $GXADMIN_LOCAL_EXTRA ] && source $GXADMIN_LOCAL_EXTRA

local_query-monthly-users-registered-by-group(){ ## [year]: Number of users registered each month for each group
	handle_help "$@" <<-EOF
        Number of users per group each month that registered. **NOTE**: Does not include anonymous users or users in no group.

        $ gxadmin local query-monthly-users-registered-by-group
            month    |            name            | count
         ------------+----------------------------+-------
          2020-08-01 | Australian_government      |     1
          2020-08-01 | Australian_researchers_mix |     1
          2020-08-01 | RMIT_users                 |     1
          2020-08-01 | UQ_users                   |     3
          2020-07-01 | Australian_government      |     1
          2020-07-01 | Australian_researchers_mix |     6
          2020-07-01 | JCU_users                  |     2
          2020-07-01 | Monash_users               |     6
          2020-07-01 | QUT_users                  |     2
          2020-07-01 | RMIT_users                 |     1
          ...
EOF

if (( $# > 0 )); then
		where=" date_trunc('year', galaxy_user.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date and"
fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', galaxy_user.create_time)::DATE AS month,
            galaxy_group.name,
            count(*)
		FROM
			galaxy_user,
            user_group_association,
            galaxy_group
		WHERE
			$where
        	galaxy_user.id = user_group_association.user_id and
        	galaxy_group.id = user_group_association.group_id
		GROUP BY
			month,
            galaxy_group.name
		ORDER BY
			month DESC
EOF
}

local_query-monthly-jobs-by-group(){ ## [year]: Number of jobs run each month per group
    handle_help "$@" <<-EOFhelp
		Number of jobs run per group per month. (Optional: for a given year.)

		$ gxadmin local query-monthly-jobs-by-group
		    month    |            name            | count
		 ------------+----------------------------+-------
		  2020-08-01 | AdelaideU_users            |    52
		  2020-08-01 | Australian_government      |   512
		  2020-08-01 | Australian_researchers_mix |   909
		  2020-08-01 | CSIRO                      |    76
		  2020-08-01 | History Retention Keeplist |    18
		  2020-08-01 | JCU_users                  |     3
		  2020-08-01 | Monash_users               |   255
		  2020-08-01 | QUT_users                  |     6
		  2020-08-01 | UNSW_users                 |    45
		  2020-08-01 | UoM_users                  |   353
		  2020-08-01 | UoSydney_users             |   369
		  ...

EOFhelp

	if (( $# > 0 )); then
        where=" date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date and"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time)::DATE AS month,
			galaxy_group.name,
			count(*)
		FROM
			job,
			galaxy_group,
			user_group_association
		WHERE
			$where
        	job.user_id = user_group_association.user_id and
        	galaxy_group.id = user_group_association.group_id
		GROUP BY
			month,
			galaxy_group.name
		ORDER BY
			month DESC
EOF
}

local_query-monthly-new-data-by-group(){ ## [year] [--human]: Amount of new data created each month per group
	handle_help "$@" <<-EOFhelp
		Amount of new data created each month per group (Optional: for a given year)

		$ gxadmin local query-monthly-new-data-by-group --human
		   month    |            name            | pg_size_pretty
		------------+----------------------------+----------------
		 2020-08-01 | AdelaideU_users            | 31 MB
		 2020-08-01 | Australian_government      | 76 GB
		 2020-08-01 | Australian_researchers_mix | 886 GB
		 2020-08-01 | CSIRO                      | 518 MB
		 2020-08-01 | History Retention Keeplist | 341 MB
		 2020-08-01 | JCU_users                  | 303 bytes
		 2020-08-01 | Monash_users               | 150 GB
		 2020-08-01 | QUT_users                  | 1715 MB
		 2020-08-01 | UNSW_users                 | 100 GB
		 2020-08-01 | UoM_users                  | 683 GB
		 2020-08-01 | UoSydney_users             | 34 GB
		 ...

EOFhelp

#size="round(sum(coalesce(dataset.total_size, dataset.file_size, 0))*9.3132257e-10) AS size"
size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) AS size"
if (( $# > 0 )); then
	for args in "$@"; do
		if [ "$args" = "--human" ]; then
			size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) AS size"
		else
			where=" date_trunc('year', dataset.create_time AT TIME ZONE 'UTC') = '$args-01-01'::date and"
		fi
	done
fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', dataset.create_time AT TIME ZONE 'UTC')::date AS month,
			galaxy_group.name,
			$size
		FROM
			dataset,
			galaxy_group,
			history_dataset_association,
			history,
			user_group_association
		WHERE
			$where
			dataset.id = history_dataset_association.dataset_id and
			history_dataset_association.history_id = history.id and
			history.user_id = user_group_association.user_id and
			user_group_association.group_id = galaxy_group.id
		GROUP BY
			month,
			galaxy_group.name
		ORDER BY
			month DESC
EOF
}

local_query-monthly-users-active-by-group(){ ## [year]: Number of unique users who ran a job per group each month
	handle_help "$@" <<-EOFhelp
		Number of unique users who ran a job per group each month (Optional: for a given year)

		$ gxadmin local query-monthly-users-active-by-group
		   month    |            name            | active_users
		------------+----------------------------+--------------
		 2020-08-01 | AdelaideU_users            |            3
		 2020-08-01 | Australian_government      |            8
		 2020-08-01 | Australian_researchers_mix |           14
		 2020-08-01 | CSIRO                      |            1
		 2020-08-01 | History Retention Keeplist |            2
		 2020-08-01 | JCU_users                  |            1
		 2020-08-01 | Monash_users               |           14
		 2020-08-01 | QUT_users                  |            5
		 2020-08-01 | RMIT_users                 |            2
		 2020-08-01 | UNSW_users                 |            4
		 2020-08-01 | UoM_users                  |            3
		 2020-08-01 | UoSydney_users             |            4
		 2020-08-01 | UQ_users                   |           33
		 2020-08-01 | USQ_users                  |            2
		 2020-08-01 | UTas_users                 |           12
		 2020-08-01 | UWA_users                  |            2
		 2020-07-01 | AdelaideU_users            |            4
		 2020-07-01 | Australian_government      |            8
		 2020-07-01 | Australian_researchers_mix |           31
		 2020-07-01 | CSIRO                      |            2
		 2020-07-01 | Curtin_users               |            1
		 2020-07-01 | GriffithU_users            |            2
		 2020-07-01 | History Retention Keeplist |            4
		 2020-07-01 | JCU_users                  |            3
		 2020-07-01 | Monash_users               |           18
		 2020-07-01 | QUT_users                  |            3
EOFhelp

	if(( $# > 0 )); then
		where=" date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date and "
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time AT TIME ZONE 'UTC')::date as month,
			galaxy_group.name,
			count(distinct job.user_id) as active_users
		FROM
			job,
			user_group_association,
			galaxy_group
		WHERE
			$where
			job.user_id = user_group_association.user_id and
			user_group_association.group_id = galaxy_group.id
		GROUP BY
			month,
			galaxy_group.name
		ORDER BY
			month DESC
EOF
}

local_query-monthly-jobs-per-destination(){ ## [year]: Number of jobs per month sent to each destination
	handle_help "$@" <<-EOFhelp
	Number of jobs sent to each destination per month (Optional: for a given year)

	$ gxadmin local query-monthly-jobs-per-destination
	   month    |     destination_id      | count
	------------+-------------------------+-------
	 2020-08-01 | pulsar-mel3_big         |   131
	 2020-08-01 | pulsar-mel3_big_canu    |    40
	 2020-08-01 | pulsar-mel3_big_trinity |    43
	 2020-08-01 | pulsar-mel3_mid         |   535
	 2020-08-01 | pulsar-mel3_small       |    99
	 2020-08-01 | pulsar-mel_big          |    32
	 2020-08-01 | pulsar-mel_mid          |  2534
	 2020-08-01 | pulsar-mel_small        |  2099
	 2020-08-01 | pulsar-paw_big          |   223
	 2020-08-01 | pulsar-paw_mid          |   597
	 2020-08-01 | slurm_16slots           |   139
	 2020-08-01 | slurm_1slot             | 10463
	 2020-08-01 | slurm_1slot_upload      |  4913
	 2020-08-01 | slurm_2slots            |   757
	 2020-08-01 | slurm_32slots           |     1
	 2020-08-01 | slurm_3slots            |  1693
	 2020-08-01 | slurm_5slots            |  2114
	 2020-08-01 | slurm_7slots            |   590
	 2020-08-01 | slurm_9slots            |   357
	 2020-08-01 |                         |   856
	 2020-07-01 | pulsar-mel3_big         |   468
	 2020-07-01 | pulsar-mel3_big_canu    |    53
	 2020-07-01 | pulsar-mel3_big_trinity |    90
	 2020-07-01 | pulsar-mel3_mid         |  9698
	 2020-07-01 | pulsar-mel3_small       |   328
	 2020-07-01 | pulsar-mel_big          |    57
EOFhelp

	if(( $# > 0 )); then
 		where="WHERE date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
 	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time AT TIME ZONE 'UTC')::DATE AS month,
			job.destination_id,
			count(*)
		FROM
			job
		$where
		GROUP BY
			month,
			job.destination_id
		ORDER BY
			month DESC
EOF
}

local_query-histogram-of-history-update-time(){
	handle_help "$@" <<-EOFhelp
	Produces data for a histogram of history update times by weeks

	$ gxadmin local query-histogram-of-history-update-time

     count |    week
    -------+------------
       408 | 2019-11-04
       453 | 2019-11-11
       361 | 2019-11-18
       233 | 2019-11-25
       385 | 2019-12-02
       187 | 2019-12-09
       149 | 2019-12-16
        57 | 2019-12-23
        50 | 2019-12-30
       109 | 2020-01-06
       122 | 2020-01-13
       191 | 2020-01-20
       176 | 2020-01-27
       252 | 2020-02-03
       235 | 2020-02-10
       347 | 2020-02-17
      9341 | 2020-02-24
       405 | 2020-03-02
       253 | 2020-03-09
       618 | 2020-03-16
       419 | 2020-03-23
       526 | 2020-03-30
       509 | 2020-04-06
       199 | 2020-04-13
EOFhelp

	read -r -d '' QUERY <<-EOF
		SELECT
            date_trunc('week', update_time AT TIME ZONE 'UTC')::date as week,
			count(*)
		FROM
			history
		WHERE
            deleted = 'false'
		GROUP BY
			week
		ORDER BY
			week
EOF
}

local_query-histogram-of-history-create-time(){
	handle_help "$@" <<-EOFhelp
	Produces data for a histogram of history create times by weeks

	$ gxadmin local query-histogram-of-history-create-time

     count |    week
    -------+------------
       408 | 2019-11-04
       453 | 2019-11-11
       361 | 2019-11-18
       233 | 2019-11-25
       385 | 2019-12-02
       187 | 2019-12-09
       149 | 2019-12-16
        57 | 2019-12-23
        50 | 2019-12-30
       109 | 2020-01-06
       122 | 2020-01-13
       191 | 2020-01-20
       176 | 2020-01-27
       252 | 2020-02-03
       235 | 2020-02-10
       347 | 2020-02-17
      9341 | 2020-02-24
       405 | 2020-03-02
       253 | 2020-03-09
       618 | 2020-03-16
       419 | 2020-03-23
       526 | 2020-03-30
       509 | 2020-04-06
       199 | 2020-04-13
EOFhelp

	read -r -d '' QUERY <<-EOF
		SELECT
            date_trunc('week', create_time AT TIME ZONE 'UTC')::date as week,
			count(*)
		FROM
			history
		WHERE
            deleted = 'false'
		GROUP BY
			week
		ORDER BY
			week
EOF
}

local_query-histogram-of-history-create-update-time(){
	handle_help "$@" <<-EOFhelp
	Produces data for a histogram of history create and update times by weeks

	$ gxadmin local query-histogram-of-history-create-update-time

EOFhelp

	read -r -d '' QUERY <<-EOF
		SELECT
            date_trunc('week', create_time AT TIME ZONE 'UTC')::date as week,
			count(create_time),
            count(update_time)
		FROM
			history
		WHERE
            deleted = 'false'
		GROUP BY
			week
		ORDER BY
			week
EOF
}

local_query-job-input-datasets() { ##? <id>: Job ID
	# similar to gxadmin query-job-inputs but with sizes
	arg_id="$1"
	handle_help "$@" <<-EOF
	Shows a table of job input datasets with file_size and total size for a given job id
	
	$ gxadmin local query-job-input-datasets 4092986755

	 hda_id  |            hda_name             |  d_id   | d_state | d_file_size | d_total_size
	---------+---------------------------------+---------+---------+-------------+--------------
	91237625 | SRR7692603:forward uncompressed | 3545195 | ok      | 4810 MB     | 4810 MB
	91237627 | SRR7692603:reverse uncompressed | 3545196 | ok      | 4845 MB     | 4845 MB

	EOF

	read -r -d '' QUERY <<-EOF
			SELECT
				hda.id AS hda_id,
				hda.name AS hda_name,
				d.id AS d_id,
				d.state AS d_state,
				pg_size_pretty(d.file_size) AS d_file_size,
				pg_size_pretty(d.total_size) AS d_total_size
			FROM job j
				JOIN job_to_input_dataset jtid
					ON j.id = jtid.job_id
				JOIN history_dataset_association hda
					ON hda.id = jtid.dataset_id
				JOIN dataset d
					ON hda.dataset_id = d.id
			WHERE j.id = $arg_id
	EOF
}


local_query-job-input-size() { ##? <id>: Job ID
	job_id="$1"
	handle_help "$@" <<-EOF

	Shows details of a job including the sum of input dataset sizes for a given job ID

	$ gxadmin local query-job-input-size 4212421

	 job_id  |          created           |          updated           | username | state |                       tool_id                        | sum_input_size | destination  | external_id
	---------+----------------------------+----------------------------+----------+-------+------------------------------------------------------+----------------+--------------+-------------
	 4212421 | 2021-03-01 23:14:05.770694 | 2021-03-01 23:14:12.965732 | koala    | error | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 1615 kB        | slurm_3slots | 444

	EOF
	read -r -d '' QUERY <<-EOF
			SELECT
				j.id as job_id,
				j.create_time as created,
				j.update_time as updated,
				u.username,
				j.state as state,
				j.tool_id as tool_id,
				(
					SELECT
					pg_size_pretty(SUM(d.total_size))
					FROM dataset d, history_dataset_association hda, job_to_input_dataset jtid
					WHERE hda.dataset_id = d.id
					AND jtid.job_id = j.id
					AND hda.id = jtid.dataset_id
				) as sum_input_size,
				j.destination_id as destination,
				j.job_runner_external_id as external_id
			FROM job j, galaxy_user u
			WHERE j.user_id = u.id
			AND j.id = $job_id
	EOF
}

local_query-job-input-size-by-tool() { ##? <tool> input tool substr,  # optional <limit>
	tool_substr="$1"
	[ ! "$2" ] && limit="10" || limit="$2"
	handle_help "$@" <<-EOF

	Produces a table of n most recently created jobs for a tool.  The first argument is a substring of the tool ID.
	The second optional argument is the number of rows to display (default 10).
	**NOTE**: since the tool argument is a substring of the ID, to specifically look for bwa jobs without including
	bwa_mem jobs the appropriate argument would be '/bwa/bwa/'

	$ gxadmin local query-jobs-input-size-by-tool multiqc

	 job_id  |          created           |          updated           |   username   | state |                       tool_id                        | sum_input_size | destination  | external_id
	---------+----------------------------+----------------------------+--------------+-------+------------------------------------------------------+----------------+--------------+-------------
	 4212521 | 2021-03-01 23:40:43.571578 | 2021-03-01 23:40:57.23172  | platypus     | ok    | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 27 kB          | slurm_3slots | 492
	 4212432 | 2021-03-01 23:19:33.729478 | 2021-03-01 23:19:46.422826 | emu          | ok    | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 18 kB          | slurm_3slots | 460
	 4212427 | 2021-03-01 23:15:36.339832 | 2021-03-01 23:15:46.32736  | koala        | ok    | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 18 kB          | slurm_3slots | 446
	 4212426 | 2021-03-01 23:15:20.785234 | 2021-03-01 23:15:32.484563 | wombat       | ok    | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 27 kB          | slurm_3slots | 445
	 4212421 | 2021-03-01 23:14:05.770694 | 2021-03-01 23:14:12.965732 | koala        | error | toolshed.g2.bx.psu.edu/repos/iuc/multiqc/multiqc/1.9 | 1615 kB        | slurm_3slots | 444

	EOF


	read -r -d '' QUERY <<-EOF
			SELECT
				j.id as job_id,
				j.create_time as created,
				j.update_time as updated,
				u.username,
				j.state as state,
				j.tool_id as tool_id,
				(
					SELECT
					pg_size_pretty(SUM(d.total_size))
					FROM dataset d, history_dataset_association hda, job_to_input_dataset jtid
					WHERE hda.dataset_id = d.id
					AND jtid.job_id = j.id
					AND hda.id = jtid.dataset_id
				) as sum_input_size,
				j.destination_id as destination,
				j.job_runner_external_id as external_id
			FROM job j, galaxy_user u
			WHERE j.user_id = u.id
			AND position('$tool_substr' in j.tool_id)>0
			ORDER BY j.create_time desc
			LIMIT $limit
	EOF
}
