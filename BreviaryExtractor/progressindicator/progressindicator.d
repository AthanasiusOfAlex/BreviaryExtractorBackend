module progressindicator;

import std.stdio;

class ProgressIndicator(T)
{
	this(long totalNumberOfTicks, long totalDisplayMarks, long min=0, double startingPercent=0)
	{
		mTotal = totalNumberOfTicks;
		mMax = min + totalNumberOfTicks;
		mMin = min;
		mCurrentTick = percentToTick(startingPercent);
		mDisplayDriver = new T(totalDisplayMarks);
	}

	void uptick(long ticks=1)
	{
		if(mCurrentTick + ticks <= mMax && mCurrentTick + ticks >= mMin) // Don't update if out of range.
		{
			mCurrentTick += ticks;
			mDisplayDriver.update(currentPercent);
		}
	}

	@property void setPercent(double percent)
	{
		if(percent<=100 && percent >=0)  	// Don't do anything unless percent is 0-100.
		{
			mCurrentTick = percentToTick(percent);
			mDisplayDriver.update(currentPercent);
		}
	}

	@property long currentTick()
	{
		return mCurrentTick;
	}

	@property double currentPercent()
	{
		return tickToPercent(mCurrentTick);
	}

	void handler()
	{
		uptick;
	}

protected:
	immutable long mMin;
	immutable long mMax;
	immutable long mTotal;
	long mCurrentTick;
	T mDisplayDriver;

private:
	long percentToTick(double percent)
	{
		import std.math;

		return mMin + cast(long)round(cast(double)mTotal * percent / 100);
	}

	double tickToPercent(long tick)
	{
		return cast(double)(tick - mMin) / cast(double)mTotal * 100;
	}

}

private abstract class ProgressDisplayDriver
{
	void update(double newPercentage) {}
	
protected:
	long mMaxMarks;
	long mCurrentMarkCount;
	
	long percentToMark(double percent)
	{
		import std.math;
		
		return cast(long)round(cast(double)mMaxMarks * percent / 100);
	}
}

class ProgressEmitNumbers : ProgressDisplayDriver
{
	this(long maxMarks) {}
	override void update(double newPercentage)
	{
		writeln(newPercentage);
		stdout.flush;
	}
}

class ProgressStdout : ProgressDisplayDriver
{
	this(long maxMarks, string mark = "=")
	{
		import std.array;
		mMaxMarks = maxMarks;
		mMark = mark;
		mBlankMark = replicate(" ", mMark.length);
		initialize();
	}

	~this()
	{
		// Fill up any space not yet filled with blank spaces.
		if (mCurrentMarkCount<mMaxMarks)
		{
			foreach(i; 0..mMaxMarks-mCurrentMarkCount)	// std.array.replicate won't work here. No idea why.
			{
				write(mBlankMark);
			}
			finalize;
		}
	}
	
	override void update(double newPercentage)
	{
		long newMarkCount = percentToMark(newPercentage);

		if (newMarkCount > mMaxMarks)	// Don't allow the mark count to exceed the maximum allowed.
		{
			newMarkCount = mMaxMarks;
		}
		
		if (newMarkCount > mCurrentMarkCount)	// Only bother doing anything if more marks need to be drawn.
		{
			import std.array;

			write(replicate(mMark, newMarkCount-mCurrentMarkCount));

			stdout.flush;
			mCurrentMarkCount = newMarkCount;
		}
		
		if (mCurrentMarkCount==mMaxMarks)		// Finalize if we have reached the total.
		{
			finalize();
		}
	}
	
private:
	string mMark;
	string mBlankMark;
	bool m_isFinalized = false;
	
	void initialize()
	{
		write("[");
		stdout.flush;
	}
	
	void finalize()
	{
		if (!m_isFinalized)	// Never finalize if already finalized.
		{
			write("]");
			stdout.flush;
		}
	}
}